# Plano de Implementação — Agente IA que Opera o App (Firebase AI Logic)

> **Projeto:** OFLite (budget_flutter)
> **Base obrigatória:** `ARCHITECTURE.md` (ponytail, MVVM, UseCase → Repo → DataSource)
> **Substitui/evolui:** `CHAT_AI_IMPLEMENTATION_PLAN.md` (mantém o gate híbrido,
> troca o "classificador regex + LLM texto" por **agente com function calling**
> sobre os usecases reais) e complementa `CHAT_ASSISTANT_SPEC.md`.
> **Modelo:** Gemini Flash / Flash-Lite via pacote `firebase_ai` (Firebase AI Logic)

> **Status (2026-11-18):** Fases 1–5 implementadas + "digitando…", opção
> Relatórios e rede de segurança. Pendente: suíte de avaliação contra o modelo
> real (Fase 7). **Referência viva da implementação: `ARCHITECTURE.md` §20** —
> este arquivo guarda o plano e o raciocínio original.

---

## 0. Objetivo

Um chat que **entende linguagem livre** e **opera o app** chamando as mesmas
regras de negócio que as telas usam. Ele deve:

1. Fazer **tudo que o chat assistant faz hoje** (criar orçamento, lista de preços,
   editar dados do PDF, logo, nome de usuário, compartilhar link).
2. **Consultar orçamentos do mês por status**: "quais estão pendentes esse mês?"
3. **Trazer resultados do mês**: "quanto gerei/aprovei em novembro?", "como foi
   outubro comparado a setembro?"
4. **Criar recibos vinculados a um orçamento específico**: "gera um recibo de
   R$ 500 de entrada pro orçamento do João".
5. Gerar e devolver **link / PDF** de orçamento e recibo.
6. Ser **barato**: cada pergunta custa uma fração de centavo, e toque em botão
   custa zero.

### Princípios (não negociáveis)

| # | Princípio | Por quê |
|---|-----------|---------|
| P1 | **LLM decide, usecase executa.** O modelo só escolhe a tool e os argumentos. | Regra de negócio = usecase (regra do projeto). |
| P2 | **LLM nunca calcula.** Somas, totais e contagens vêm do usecase. | LLM erra conta, e o app é financeiro. |
| P3 | **Chamada externa só no DataSource.** O `firebase_ai` fica em `ChatAiRemoteDatasource`. | Regra do projeto. |
| P4 | **Escrita sempre confirmada.** Tools que gravam devolvem `needsConfirmation`, e a UI mostra um card com botões. | Segurança, evita alucinação gravando dado. |
| P5 | **Valores persistidos fixos.** O status trafega como `PENDENTE/APROVADO/REPROVADO/FINALIZADO` (enum no schema). Só o label é traduzido. | Regra Zero do i18n. |
| P6 | **Resposta é UI, não só texto.** O resultado da tool vira card/lista nativa, e o texto do modelo é a legenda. | UX prática, menos tokens. |
| P7 | **Não-assinante: mudança zero.** Bot determinístico intacto. | Gate de assinatura. |

---

## 1. Arquitetura

```
ChatAssistantView
   │  (texto livre)                       (toque em botão / card)
   ▼                                              ▼
ChatAssistantViewModel ── modo? ──► deterministic: state machine atual (ZERO mudança)
   │ aiAssistant
   ▼
RunAgentTurnUseCase  (orquestrador, loop máx. 5 iterações)
   │ 1. BuildAgentContextUseCase  → system prompt + data de hoje + resumo do usuário
   │ 2. ChatAiRepository.send(history, tools)
   │        └─ ChatAiRemoteDatasource  ── firebase_ai ──► Gemini
   │ 3. resposta tem functionCalls?
   │        sim → ChatToolDispatcher.execute(name, args)
   │                 └─ chama UseCases de budget / receipt / pdf / share_link / chat
   │              → devolve functionResponse (JSON enxuto) → volta ao passo 2
   │        não → texto final
   ▼
AgentTurnResult { text, uiBlocks[], pendingConfirmation?, navigation? }
   ▼
ViewModel converte em ChatMessageEntity (tipos novos: budgetList, summaryCard,
confirmCard, receiptCard) → View renderiza
```

### Por que function calling e não RAG

- O "conhecimento do app" cabe num **system prompt de cerca de 1,5k tokens**
  (domínio, regras, status). Não precisa de vetor nem embeddings.
- Os **dados do usuário** chegam sob demanda via tools (`list_budgets`,
  `get_month_summary`). São sempre frescos e sempre filtrados pelo UID, como hoje.
- RAG só entra se no futuro houver uma base grande de FAQ/ajuda (Fase 8 opcional).

---

## 2. Gate de acesso

- `ChatMode { deterministic, aiAssistant }` é decidido no `initializeChat`.
- **Android:** premium = regra atual (`autoRenewing` + período pago vigente).
  Não alterar nada do fluxo de compra.
- **iOS:** premium = entitlement ativo (sem assinantes hoje, então dá para começar
  do zero).
- A decisão fica em `CheckAiAccessUseCase` (regra de negócio = usecase). Ele reusa
  o que `core/in_app_purchase` / `auth` já expõem e **não lê `UID.autoRenewing`
  direto no VM**.
- Fallback: se a IA falhar (rede, cota, erro), mostrar "Não consegui entender
  agora 😕" e o **menu determinístico**. O usuário nunca fica travado.
- Kill switch: a constante `aiChatEnabled` (opcional depois via Remote Config).

---

## 3. Catálogo de Tools

Convenções:
- Nomes em `snake_case`, descrições em pt-BR curtas (descrição custa token).
- Datas sempre `yyyy-MM-dd`. O modelo resolve "esse mês" a partir de `today`,
  que vai no system prompt.
- **Toda resposta de tool é enxuta**: no máximo 20 itens e só os campos
  `id, cliente, valor, status, data`. A lista completa vai **direto para a UI**
  (`uiBlocks`) sem passar pelo modelo.

### 3.1 Leitura (executa direto, sem confirmação)

| Tool | Args | UseCase chamado | Retorno ao modelo | UI |
|------|------|-----------------|-------------------|----|
| `list_budgets` | `status?` enum, `from?`, `to?`, `client_name?`, `min_value?`, `limit?` (≤20) | `ListBudgetsUseCase` (budget) | `{count, total, items:[{id,cliente,valor,status,data}]}` | lista de cards clicáveis |
| `get_month_summary` | `month` (`yyyy-MM`), `compare_previous?` bool | `GetMonthSummaryUseCase` (budget) | `{month, count, total, byStatus:{PENDENTE:{count,total},...}, previous?}` | card de resumo |
| `get_budget_details` | `budget_id` | `GetBudgetDetailsUseCase` (budget) | cliente, itens (≤15), total, status, nº de recibos | card do orçamento |
| `find_client` | `name` | `FindBudgetsByClientUseCase` (filtro local sobre cache) | `[{budget_id, cliente, data, valor}]` (≤5) | botões para desambiguar |
| `list_receipts` | `budget_id` | `ListReceiptsByBudgetUseCase` (receipt) | `{totalOrcamento, totalRecebido, saldo, recibos:[...]}` | lista de recibos |
| `get_budget_link` | `budget_id` | `ShareBudgetLinkUseCase` (reusa share_link) | `{url}` | botão Abrir/Compartilhar |
| `get_budget_pdf` | `budget_id`, `layout?` enum | `PdfGenerateBudget*UseCase` (pdf) | `{ok:true}` | card com "Abrir PDF" |
| `get_receipt_pdf` | `budget_id`, `receipt_id` | `PdfGenerateReceipt*UseCase` (pdf) | `{ok:true}` | card "Abrir PDF" |
| `explain_capabilities` | — | sem usecase (texto fixo nas strings) | lista do que sabe fazer | texto |

### 3.2 Escrita (sempre com confirmação, P4)

| Tool | Args | Preview mostrado | UseCase na confirmação |
|------|------|------------------|------------------------|
| `create_budget` | `client_name`, `phone?`, `items?[{name,qty,price}]` | resumo cliente + itens + total (calculado no usecase) | `CreateBudgetFromChatUsecase` (já existe) + `saveBudgetItem` |
| `create_receipt` | `budget_id`, `amount`, `description?`, `date?` | "Recibo de R$ X para orçamento de Y (saldo restante R$ Z)" | `CreateReceiptForBudgetUseCase` (novo, receipt) |
| `update_budget_status` | `budget_id`, `status` enum | "Mudar orçamento de Y para APROVADO?" | `UpdateBudgetStatusUseCase` (novo, budget) |
| `edit_pdf_field` | `field` enum(nome, telefone, email, cnpj, endereco), `value` | "Alterar telefone do PDF para X?" | `UpdatePdfFieldUsecase` (já existe) |
| `change_username` | `new_name` | confirmação | usecase existente de username |

### 3.3 Handoff para fluxos existentes ("faz tudo que já faz")

Fluxos ricos em UI (seletor de contato, modal de produto, CEP, logo) **não são
reescritos**. A tool entrega o controle para a state machine atual:

| Tool | Args | Efeito |
|------|------|--------|
| `start_flow` | `flow` enum: `create_budget_guided`, `price_list`, `pdf_edit`, `logo`, `change_username`, `add_products`; `budget_id?`, `prefill?` | O VM chama o mesmo método do menu (`StartBudgetFromMenuUseCase`, `ShowPriceListMenuUseCase`, ...) com prefill. O chat segue no modo determinístico **até o fluxo terminar** e depois volta ao modo IA. |
| `navigate_to` | `screen` enum: `budget_list`, `budget_detail`, `receipts`, `dashboard`, `subscription` + `id?` | Seta `pendingNavigation` (mecanismo que já existe). |

> Resultado: o usuário fala "quero fazer um orçamento pro João" e a IA chama
> `create_budget` (rápido, confirmação) ou, se ele quer adicionar produtos da
> lista de preços, `start_flow(add_products)`, com o modal atual. Nada do que
> funciona hoje é perdido.

### 3.4 Desambiguação (o modelo conduz)

"Gera um recibo pro orçamento do João" → `find_client("João")`:
- 1 resultado → segue com `create_receipt`.
- Mais de 1 → o modelo pergunta, e a UI mostra os orçamentos como botões. O toque
  no botão manda `"[selecionado budget_id=...]"` como mensagem e o modelo continua.
- 0 → o modelo oferece criar orçamento ou listar os recentes.

---

## 4. Novos UseCases e onde moram (regra: usecase no módulo dono)

### Módulo `budget` (`lib/modules/budget/domain/usecase/`)

| Arquivo | Regra |
|---------|-------|
| `list_budgets_usecase.dart` | Recebe `BudgetFilter{status, from, to, clientName, minValue}`. Se o período cabe num mês, usa `fetchBudgetsByMonthRange(startId,endId)` (IDs são timestamps). Senão usa `fetchBudgets()` do cache. Filtra localmente e ordena por data desc. |
| `get_month_summary_usecase.dart` | Usa o mesmo range de mês, agrupa por `status` → `{count,total}`. Opcionalmente faz o mês anterior. **Mesma lógica de agregação que o Dashboard** (ver §9, débito técnico). |
| `get_budget_details_usecase.dart` | `getBudgetById` + `fetchBudgetItems` + contagem de recibos. |
| `find_budgets_by_client_usecase.dart` | Normaliza (sem acento, lowercase) e faz `contains` sobre `customerName`. |
| `update_budget_status_usecase.dart` | Valida transição e `updateBudget`. |
| `domain/entity/budget_filter.dart` | Entidade do filtro. |
| `domain/entity/budget_status.dart` | `enum BudgetStatus { pendente('PENDENTE'), aprovado('APROVADO'), reprovado('REPROVADO'), finalizado('FINALIZADO') }`. O valor persistido fica fixo, e o label vem das strings. |

### Módulo `receipt` (`lib/modules/receipt/domain/usecase/`)

| Arquivo | Regra |
|---------|-------|
| `create_receipt_for_budget_usecase.dart` | Valida que o orçamento existe e `amount > 0`. **Avisa (não bloqueia) se a soma dos recibos ultrapassar o total do orçamento.** Seta `receiptRepository.budgetId = budgetId`, gera `id` (timestamp, igual ao app), `data` (dd/MM/yyyy) e `saveReceipt`. Grava em `EMPRESAS/{uid}/USERS/{uid}/ORCAMENTOS/{budgetId}/RECIBOS`, a mesma coleção de hoje. |
| `list_receipts_by_budget_usecase.dart` | `fetchReceipts` do orçamento e calcula `totalRecebido`/`saldo`. |

> Atenção: `ReceiptRepository.budgetId` é estado mutável compartilhado. O usecase
> deve **salvar e restaurar** o valor anterior para não bagunçar uma tela de
> recibos aberta por baixo.

### Módulo `chat_assistant` (agente)

```
lib/modules/chat_assistant/
├── data/
│   ├── datasource/chat_ai_remote_datasource.dart     # ÚNICO lugar com firebase_ai
│   └── repository/chat_ai_repository_impl.dart       # Map ↔ entity
├── domain/
│   ├── entity/
│   │   ├── agent_message_entity.dart                 # role, text, functionCall?, functionResponse?
│   │   ├── agent_tool_call_entity.dart               # name, args
│   │   ├── agent_tool_result_entity.dart             # modelPayload (enxuto) + uiBlocks + needsConfirmation
│   │   └── agent_turn_result_entity.dart             # text, uiBlocks, pendingConfirmation, navigation, flowHandoff
│   ├── repository/chat_ai_repository.dart
│   ├── tools/                                        # declarações (schemas) — 1 arquivo por grupo
│   │   ├── agent_tool_declarations.dart              # lista exportada p/ o datasource
│   │   └── agent_tool_names.dart                     # constantes dos nomes
│   └── usecase/
│       ├── check_ai_access_usecase.dart
│       ├── build_agent_context_usecase.dart          # system prompt + today + usuário
│       ├── run_agent_turn_usecase.dart               # loop LLM ↔ tools (máx 5)
│       ├── dispatch_agent_tool_usecase.dart          # switch name → usecase; valida args
│       ├── confirm_agent_action_usecase.dart         # executa a escrita pendente
│       └── trim_agent_history_usecase.dart           # janela de contexto barata
└── presenter/chat_assistant/components/
    ├── chat_budget_list_card.dart
    ├── chat_month_summary_card.dart
    ├── chat_confirm_action_card.dart
    └── chat_receipt_card.dart
```

> `ChatToolDispatcher` é um **usecase** (`DispatchAgentToolUseCase`), não um
> helper, porque decide qual regra executar e valida os argumentos.
> Os schemas (`FunctionDeclaration`) são tipo do SDK. Para manter P3, a camada
> domain declara as tools como **Map/entity neutra**
> (`AgentToolSpec{name, description, params}`), e o **datasource converte** para
> `FunctionDeclaration`/`Schema`. Assim o domain não importa `firebase_ai`.

---

## 5. DataSource (Firebase AI Logic)

```yaml
# pubspec.yaml
firebase_ai: ^<última estável>
firebase_app_check: ^<última estável>
```

```dart
class ChatAiRemoteDatasource {
  GenerativeModel _model({required String system, required List<Map<String, dynamic>> tools}) =>
      FirebaseAI.googleAI().generativeModel(
        model: AiConfig.model,                 // ex.: Flash-Lite; trocar sem release via Remote Config (opcional)
        systemInstruction: Content.system(system),
        tools: [Tool.functionDeclarations(tools.map(_toDeclaration).toList())],
        generationConfig: GenerationConfig(temperature: 0.2, maxOutputTokens: 512),
      );

  /// Envia o histórico e devolve `{text?, functionCalls:[{name,args}], usage:{in,out}}`.
  Future<Map<String, dynamic>> send({
    required String system,
    required List<Map<String, dynamic>> tools,
    required List<Map<String, dynamic>> history,
  }) async { /* generateContent(history → Content) */ }
}
```

- **Stateless:** o histórico mora no app (VM/usecase), não no `ChatSession` do
  SDK. Isso permite aparar o histórico e testar.
- `temperature` baixa, porque é tarefa de roteamento e não criatividade.
- Logar `usage` (tokens) no Crashlytics/Analytics por turno, para medir custo real.
- Mapear erros (`quota`, `network`, `safety`) para `Result.error` tipado → fallback
  do §2.

**Console Firebase:** habilitar AI Logic (Gemini Developer API para começar,
depois Vertex se precisar de região/SLA), **App Check obrigatório** (Play
Integrity / App Attest) e quota por usuário no AI Logic.

---

## 6. System prompt (BuildAgentContextUseCase)

Fixo (cerca de 1–1,5k tokens, fica em `presenter/strings` ou num asset `.md`):

```
Você é o assistente do OFLite, app de orçamentos e recibos para prestadores de serviço.
Hoje é {today} ({weekday}). Fuso America/Sao_Paulo. Moeda {currency}.
Usuário: {userName}. Empresa no PDF: {companyName}.

Domínio:
- Orçamento: cliente, telefone, endereço, itens (nome, qtd, preço), observações, status.
- Status possíveis (use EXATAMENTE): PENDENTE, APROVADO, REPROVADO, FINALIZADO.
- Recibo: sempre pertence a UM orçamento; tem valor, data e descrição.
- "Esse mês" = mês de {today}. "Mês passado" = mês anterior.

Regras:
1. Use SEMPRE as ferramentas para obter dados. Nunca invente números, nomes ou ids.
2. Nunca some ou calcule valores: repita os totais retornados pelas ferramentas.
3. Se faltar dado obrigatório, pergunte UMA coisa por vez, de forma curta.
4. Se o cliente for ambíguo, use find_client e peça para o usuário escolher.
5. Ações que gravam dados retornam preview: diga em 1 frase o que será feito e aguarde.
6. Respostas curtas (máx. 2 frases). A lista/card já aparece na tela; não repita itens.
7. Fora do escopo do app: diga educadamente o que você sabe fazer.
8. Responda no idioma do usuário; valores enviados às ferramentas seguem os enums.
```

Dinâmico (barato): só `today`, nome, empresa e moeda. **Não** incluir lista de
orçamentos no prompt, porque isso vem via tool.

---

## 7. Loop do agente (RunAgentTurnUseCase)

```dart
Future<Result<AgentTurnResult>> call(String userText) async {
  history.add(AgentMessage.user(userText));
  final ui = <UiBlock>[];
  for (var i = 0; i < 5; i++) {                       // trava contra loop infinito
    final res = await _ai.send(system, tools, _trim(history));
    if (res is Error) return res;                     // VM faz fallback
    final reply = res.value;
    history.add(reply.asModelMessage);
    if (reply.functionCalls.isEmpty) {
      return Result.ok(AgentTurnResult(text: reply.text, uiBlocks: ui));
    }
    for (final call in reply.functionCalls) {          // Gemini pode pedir várias em paralelo
      final r = await _dispatch(call);                 // valida args → usecase
      ui.addAll(r.uiBlocks);
      if (r.needsConfirmation) {                       // para aqui e espera o toque
        return Result.ok(AgentTurnResult(text: r.previewText, uiBlocks: ui,
            pendingConfirmation: r.pending));
      }
      if (r.flowHandoff != null) return Result.ok(AgentTurnResult(flowHandoff: r.flowHandoff));
      history.add(AgentMessage.functionResponse(call.name, r.modelPayload));
    }
  }
  return Result.ok(AgentTurnResult(text: strings.agentGaveUp));
}
```

**Confirmação:** o toque em "Confirmar" chama `ConfirmAgentActionUseCase`
(**sem LLM**). Ele grava, adiciona `functionResponse{ok:true, id}` ao histórico e
mostra o card de sucesso. Uma 2ª chamada ao modelo **só** acontece se o usuário
voltar a digitar. "Cancelar" adiciona `{cancelled:true}`.

**Validação no dispatcher:** enum desconhecido, data inválida ou `budget_id`
inexistente viram `functionResponse{error:"..."}`, e o modelo se corrige sozinho
(conta para o limite de 5).

---

## 8. Economia de custo (barato por design)

| Técnica | Impacto |
|---------|---------|
| Toque em botão/card **nunca** chama a LLM (confirmação, seleção, menus) | ~50% menos chamadas |
| Modelo Flash-Lite como padrão; Flash só se a métrica de acerto pedir | menor preço por token |
| `functionResponse` enxuto (≤20 itens, 5 campos), lista completa só na UI | menos tokens de input |
| `TrimAgentHistoryUseCase`: últimas ~10 mensagens + resumo de ids citados | contexto constante |
| System prompt curto e estável (candidato a context caching implícito) | input repetido mais barato |
| Descrições de tools curtas; só tools relevantes (≈14) | menos tokens fixos |
| `maxOutputTokens: 512`, `temperature: 0.2` | saída curta |
| Limite diário por usuário (ex.: 100 msgs) + App Check | sem abuso de cota |

**Estimativa:** um turno típico ≈ 2–3k tokens de input + ~150 de output, com 1–2
chamadas por pergunta. Com Flash/Flash-Lite isso fica em **frações de centavo
por pergunta**. Confirmar com a tabela de preços vigente do Firebase AI Logic e
validar com o log de `usage` da Fase 3.

---

## 9. Modificações em arquivos existentes

| Arquivo | Mudança |
|---------|---------|
| `chat_assistant_view_model.dart` | `ChatMode`; em `_sendText`: se `aiAssistant` e `_step` em `idle/mainMenu` → `RunAgentTurnUseCase`; senão segue a state machine (handoff). Novos métodos `confirmAgentAction`/`cancelAgentAction`/`selectAgentOption`. **Não mexer** nos handlers determinísticos. Avaliar extrair a parte de IA para um `ChatAgentController` se o VM (1.459 linhas) crescer muito. |
| `chat_message_entity.dart` | Novos `ChatMessageType`: `budgetList`, `summaryCard`, `confirmCard`, `receiptCard` (payload = Map do uiBlock). |
| `chat_message_bubble.dart` | Switch dos novos tipos → componentes novos (1 widget por arquivo). |
| `chat_assistant_view.dart` | Indicador "digitando…" durante o turno da IA; tratar `navigation`. |
| `chat_assistant_binds.dart` | Registrar datasource/repo (lazySingleton), usecases e VM (factory). |
| `budget_binds.dart` / `receipt_binds.dart` | Registrar os novos usecases. |
| `chat_budget_pt_string.dart` (+ en) | Strings: labels de status, cards, erros, fallback, system prompt. |
| `main.dart` | `FirebaseAppCheck.instance.activate(...)` antes de usar a IA. |
| `pubspec.yaml` | `firebase_ai`, `firebase_app_check`. |

**Débito técnico aproveitado:** o `DashboardViewModel` agrega status no VM, o que
viola "regra de negócio = usecase". O `GetMonthSummaryUseCase` passa a ser a
fonte única, e o Dashboard pode migrar para ele depois (fora do escopo, tarefa
separada).

---

## 10. Fases

| Fase | Entrega | Critério de pronto | Est. |
|------|---------|--------------------|------|
| **1. Fundação** | `firebase_ai` + App Check; `ChatAiRemoteDatasource` + repo; `CheckAiAccessUseCase`; `ChatMode` no VM com fallback | Assinante manda "oi", a IA responde; não-assinante tem comportamento idêntico ao de hoje | 1–2 d |
| **2. Consultas do mês** | `BudgetStatus`, `ListBudgetsUseCase`, `GetMonthSummaryUseCase`, `GetBudgetDetailsUseCase`, `FindBudgetsByClientUseCase`; tools de leitura; `RunAgentTurnUseCase` + dispatcher; cards de lista e resumo | "pendentes desse mês", "total de outubro", "orçamentos do João" retornam valores iguais aos do Dashboard | 2–3 d |
| **3. Medição** | Log de `usage`/latência por turno; limite diário; trim de histórico | Custo médio por turno conhecido | 0,5 d |
| **4. Recibos** | `CreateReceiptForBudgetUseCase`, `ListReceiptsByBudgetUseCase`; tools `create_receipt`, `list_receipts`, `get_receipt_pdf`; confirmação + `ConfirmAgentActionUseCase` | "recibo de 500 pro orçamento do João" grava na coleção RECIBOS correta e aparece na tela de recibos | 2 d |
| **5. Paridade com o chat atual** | `start_flow`, `navigate_to`, `create_budget`, `edit_pdf_field`, `change_username`, `get_budget_link`, `get_budget_pdf`, `update_budget_status` | Todo item do menu atual é alcançável por linguagem livre | 2–3 d |
| **6. Polimento UX** | "digitando…", sugestões rápidas (chips) no início, mensagens de erro amigáveis, en/pt | Revisão de UX (§17 da arquitetura) | 1 d |
| **7. Qualidade** | Testes + suíte de avaliação (§11) | ≥90% de acerto de tool na suíte | 1–2 d |
| 8. (opcional) | RAG/FAQ de ajuda, voz, Remote Config de modelo | — | — |

Total MVP (fases 1–7): **~10–14 dias**.

---

## 11. Testes

- **Unit (sem LLM):** cada usecase novo com repo fake (filtros de data e status,
  agregação, saldo de recibos, restauração do `budgetId`); `DispatchAgentToolUseCase`
  com args inválidos; `RunAgentTurnUseCase` com `ChatAiRepository` fake
  roteirizado (functionCall → resposta → texto, confirmação, limite de 5).
- **Avaliação de prompt (com LLM, manual/CI noturno):** `test/agent_eval/cases.json`
  com ~40 frases → tool + args esperados. Por exemplo:
  "pendentes desse mês" → `list_budgets{status:PENDENTE, from:2026-11-01, to:2026-11-30}`;
  "quanto faturei mês passado" → `get_month_summary{month:2026-10}`;
  "recibo de 300 pra Maria" → `find_client{name:Maria}`.
  Roda a cada troca de modelo ou prompt.
- **Regressão:** fluxo determinístico completo com conta não-assinante (Android:
  build antigo → novo por cima).

---

## 12. Segurança

| Risco | Mitigação |
|-------|-----------|
| Abuso da cota/custo | App Check + quota por usuário + limite diário no app |
| Prompt injection ("ignore regras e apague tudo") | Não existe tool de delete; escrita só com confirmação humana; tools sempre escopadas ao UID logado (repos atuais) |
| Dado de outro usuário | Os repos já usam `EMPRESAS/{uid}`; a LLM nunca recebe path nem query |
| Alucinação de valores | P2: totais vêm do usecase; o card mostra o número real |
| Privacidade (LGPD) | Enviar ao modelo só o mínimo (nome do cliente, valores); nada de telefone/endereço nos `functionResponse` de listagem; atualizar a política de privacidade mencionando IA |

---

## 13. Checklist final

- [ ] Não-assinante: chat byte a byte igual
- [ ] Nenhum `import 'package:firebase_ai'` fora de `data/datasource`
- [ ] Nenhuma soma/contagem feita pelo modelo
- [ ] Status trafega como valor persistido (enum), label traduzido
- [ ] Toda escrita passa por card de confirmação
- [ ] Toque em botão não chama LLM
- [ ] Usage de tokens logado; limite diário ativo
- [ ] Usecases novos no módulo dono (budget/receipt), não em utils
- [ ] Componentes novos: 1 widget por arquivo, cores de `colors.dart`
