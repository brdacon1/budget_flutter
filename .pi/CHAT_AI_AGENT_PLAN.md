# Plano de Implementação — Agente IA que Opera o App (Firebase AI Logic)

> **Projeto:** OFLite (budget_flutter)
> **Base obrigatória:** `ARCHITECTURE.md` (ponytail, MVVM, UseCase → Repo → DataSource)
> **Substitui/evolui:** `CHAT_AI_IMPLEMENTATION_PLAN.md` (mantém o gate híbrido,
> troca o "classificador regex + LLM texto" por **agente com function calling**
> sobre os usecases reais) e complementa `CHAT_ASSISTANT_SPEC.md`.
> **Modelo:** Gemini Flash / Flash-Lite via pacote `firebase_ai` (Firebase AI Logic)

> **Status (2026-11-19):** Fases 1–5 implementadas + "digitando…", opção
> Relatórios e rede de segurança. Fase 9 (relatório de recibos) implementada;
> pendente publicar regras/índices `collectionGroup` no Firestore (§14.4). Pendente: suíte de avaliação contra o modelo
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
| **9. Relatório de recibos** | `GetReceiptsReportUseCase` (receipt) + tool `get_receipts_report` + card `receiptsReportCard` (ver §14) | "recibos dessa semana" / "quanto recebi em novembro" mostram contagem e valores iguais à soma das telas de recibo | 2–3 d |
| **11. Comprovantes de pagamento** | Botão "+" com painel de anexos (Fotos/Câmera/Documento), envio por compartilhamento do sistema (Android/iOS), vínculo a orçamento, lista `COMPROVANTES` com visualizador (ver §15) | Assinante anexa até 2 imagens ou 1 PDF, escolhe o orçamento, dá nome (e valor opcional) e vê o item na lista de comprovantes do orçamento | 5–7 d |
| **10. Saldo do orçamento** | `GetBudgetBalanceUseCase` (receipt) = total do orçamento − pagamentos dos recibos; tool `get_budget_balance` + saldo nos relatórios (ver §14.9) | "quanto falta o João pagar?" e "orçamentos com saldo em aberto" batem com as telas | 1–2 d |

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

---

## 14. Fase 9 — Relatório de recibos por semana/mês (só assinantes)

### 14.1 Problema

Hoje, na opção **Relatórios**, a pergunta "crie um relatório de recibos gerados
essa semana" cai no texto do modelo: *"O OFLite não possui relatórios semanais
de recibos…"*. O motivo é que só existe `list_receipts(budget_id)`, ou seja,
recibos de **um** orçamento. Não há tool que agregue recibos de todos os
orçamentos por período.

### 14.2 Escopo

- Perguntas como: "quantos recibos gerei essa semana?", "valor dos recibos de
  novembro", "recibos do mês passado comparado com este", "relatório de recibos
  de 01/11 a 15/11".
- Saída: **quantidade** de recibos, **valor total** (`VALORTOTAL`), quebra por
  dia (semana) ou por semana (mês), top 5 orçamentos/clientes e comparação
  opcional com o período anterior.
- **Só assinantes.** A tool só existe no modo `aiAssistant`, que já é decidido
  por `CheckAiAccessUseCase` (§2). Não-assinante: mudança zero (P7). O usecase
  **não** checa assinatura de novo, porque o gate é do modo e não da regra.

### 14.3 Regras de domínio

| Regra | Decisão |
|-------|---------|
| Data do recibo | O **ID do recibo é o timestamp (ms)** de criação (`CreateReceiptForBudgetUseCase` e telas). Usar o ID. Fallback: `DATA` (`dd/MM/yyyy`) se o ID não for numérico (docs legados). |
| "Essa semana" | Segunda 00:00 → domingo 23:59:59.999 (`America/Sao_Paulo`). "Semana passada" = semana anterior. O modelo resolve as datas a partir de `today` (já no system prompt) e manda `from`/`to` em `yyyy-MM-dd`. |
| "Esse mês" | Igual ao §6: mês de `today`, último dia inteiro (mesma regra de `ListBudgetsUseCase`, §20.5 da arquitetura). |
| Valor emitido | Soma de `VALORTOTAL` dos recibos, feita **no usecase** (P2). Recibo sem valor conta na quantidade com 0. |
| Valor recebido | Soma de `PRECO` dos `PAGAMENTOS` de cada recibo (mesma regra de `ListReceiptsByBudgetUsecase`). **É este número que a Fase 10 subtrai do total do orçamento.** O relatório mostra os dois (emitido e recebido), porque podem divergir. |
| Data do pagamento | Para o relatório por período, conta a data do **recibo** (pagamento não tem data própria). Se um dia o pagamento ganhar data, só o agregador muda. |
| Período máximo | 366 dias. Acima disso, a tool devolve `{error}` e o modelo pede um período menor. |
| Orçamento excluído | Recibo órfão não aparece (consequência natural do caminho no Firestore). |

### 14.4 Dados — como buscar recibos de todos os orçamentos

Recibos moram em `EMPRESAS/{uid}/USERS/{uid}/ORCAMENTOS/{budgetId}/RECIBOS/{id}`.
Não existe consulta por período hoje. Opções:

| Opção | Custo de leitura | Decisão |
|-------|------------------|---------|
| A. Iterar `fetchBudgets()` e buscar `RECIBOS` de cada um | N consultas (1 por orçamento) | ❌ lento e caro |
| B. `collectionGroup('RECIBOS')` limitado ao caminho do usuário via `orderBy(FieldPath.documentId)` + `startAt/endAt` no prefixo `EMPRESAS/{uid}/USERS/{uid}/` e filtro de período local | 1 consulta; lê os recibos do usuário | ✅ **MVP** |
| B+. Igual a B, mais uma 2ª consulta `collectionGroup('PAGAMENTOS')` com o mesmo prefixo; junta pelo caminho (`budgetId`/`receiptId`) | 2 consultas por sessão | ✅ **MVP** (necessário para "recebido" e para a Fase 10) |
| C. Gravar campo novo `CRIADOEM` (Timestamp) e consultar `collectionGroup` com `where` por período | 1 consulta, só o período | ⏭️ evolução, porque recibos antigos não têm o campo |

**Decisão:** B+ agora, com cache em memória de 1 minuto (as telas de recibo
gravam sem passar pelo ledger) e `invalidate()` após `CreateReceiptForBudgetUseCase`. C fica como débito técnico, porque mudar o formato
gravado exige migração (e `Receipt.toJson` mantém as 4 chaves por regra).

Configuração necessária:
- `firestore.rules`: liberar `match /{path=**}/RECIBOS/{id}` para leitura só
  quando `path` começa com `EMPRESAS/{request.auth.uid}`.
- Mesma regra para `match /{path=**}/PAGAMENTOS/{id}`.
- Índices de collection group em `RECIBOS` e `PAGAMENTOS` (`__name__` ASC), em
  `firestore.indexes.json`.

### 14.5 Arquivos novos e alterados (fluxo UseCase → Repo → DataSource)

**Módulo `receipt`**

| Arquivo | O que faz |
|---------|-----------|
| `data/datasource/receipt_remote_datasource.dart` | **+** `getAllUserReceipts(uid)`: a consulta `collectionGroup('RECIBOS')` da opção B+. Devolve `Map` com `id`, `budgetId` (= `doc.reference.parent.parent!.id`) e os campos. |
| `data/datasource/receipt_payment_remote_datasource.dart` | **+** `getAllUserPayments(uid)`: `collectionGroup('PAGAMENTOS')` com o mesmo prefixo. Devolve `Map` com `budgetId`, `receiptId` (tirados do caminho) e os campos. |
| `domain/repository/receipt_ledger_repository.dart` + `data/repository/receipt_ledger_repository_impl.dart` | **Repo novo, só leitura:** `fetchLedger({forceRefresh})` → `Result<ReceiptLedger>`. Junta recibos e pagamentos. **Não** usa nem altera os `budgetId`/`receiptId` compartilhados. Cache em memória, invalidado por `invalidate()` (chamado após `CreateReceiptForBudgetUseCase` e quando a tela de recibos salvar/excluir). |
| `domain/entity/receipt_ledger.dart` | **Base comum das Fases 9 e 10.** `ReceiptLedger{Map<budgetId, List<LedgerReceipt>>}`; `LedgerReceipt{Receipt receipt, String budgetId, DateTime createdAt, List<PaymentCustomer> payments, double issued, double paid}`. `issued`/`paid` calculados uma vez na montagem. |
| `domain/entity/receipts_report.dart` | `{from, to, count, issued, paid, buckets:[{label, start, count, issued, paid}], topBudgets:[{budgetId, cliente, count, paid}], previous?{count,issued,paid}}`. Campos com nome igual aos da Fase 10 (`paid`).. |
| `domain/usecase/get_receipts_report_usecase.dart` | Lê o `ReceiptLedger`. Recebe `ReceiptsReportFilter{from, to, groupBy(day/week/auto), comparePrevious}`. Valida o período, filtra por `createdAt`, soma `issued` e `paid`, monta os buckets e busca o nome do cliente dos top 5 via `BudgetRepository.getBudgetById` (cache). `comparePrevious` calcula o período anterior com o mesmo tamanho. |
| `receipt_binds.dart` | Registrar o usecase. |

**Módulo `chat_assistant`**

| Arquivo | O que faz |
|---------|-----------|
| `domain/usecase/dispatch_agent_tool_usecase.dart` | Declarar `get_receipts_report` (`AgentToolSpec`): `from` (string, req.), `to` (string, req.), `group_by` (enum `day`/`week`/`auto`), `compare_previous` (bool). Validar datas e `from ≤ to`. Devolver o `modelPayload` enxuto `{count, total, previous?, topCliente}` (sem buckets: o card mostra) e o uiBlock `receiptsReportCard` com o relatório completo. |
| `domain/entity/chat_message_entity.dart` | **+** `ChatMessageType.receiptsReportCard`. |
| `presenter/chat_assistant/components/chat_receipts_report_card.dart` | Card: período, nº de recibos, total (moeda local), variação vs. anterior (▲/▼ %, calculada no usecase), mini-barras por bucket, top clientes clicáveis (`open_budget|<id>`). 1 widget por arquivo, cores de `colors.dart`. |
| `presenter/.../chat_message_bubble.dart` | Switch do tipo novo. |
| `presenter/strings/chat_budget_pt_string.dart` (+ en) | Labels do card; no `aiSystemPrompt`, linha nova: *"Recibos por período (semana/mês) → get_receipts_report. Semana = segunda a domingo."*; exemplo na opção Relatórios: *"Ex.: Quantos recibos gerei essa semana?"*. |
| `show_reports_prompt_usecase.dart` | Incluir o exemplo de recibos no texto do prompt de Relatórios. |

### 14.6 Contrato da tool

```
get_receipts_report(from: "2026-11-16", to: "2026-11-22", group_by: "day", compare_previous: true)
→ modelo: {"count":7,"issued":3450.0,"paid":3000.0,"previous":{"count":4,"paid":2100.0},"topCliente":"João"}
→ UI:     receiptsReportCard { ...relatório completo }
→ texto:  "Você gerou 7 recibos nesta semana (R$ 3.450,00), com R$ 3.000,00 recebidos (↑ vs. semana passada)."
```

Leitura → executa direto, sem confirmação (P4 vale só para escrita).
Erros (`datas inválidas`, `período > 366 dias`, falha de rede) viram `{error}`
no `functionResponse` e seguem a rede de segurança do §20.8.

### 14.7 Testes

- **Unit `GetReceiptsReportUseCase`** (repo fake): semana segunda–domingo;
  último dia inteiro; ID não numérico → usa `DATA`; recibo sem valor; buckets
  por dia e por semana; `comparePrevious` com mesmo tamanho; período > 366 →
  erro; top 5 ordenado por total.
- **Unit `ReceiptLedgerRepositoryImpl`**: junta pagamentos ao recibo certo pelo caminho; recibo sem pagamento → `paid = 0`; pagamento órfão ignorado; não altera `budgetId`/`receiptId`; cache e `invalidate()`.
- **Dispatcher:** `from > to`, data inválida, `group_by` desconhecido → `{error}`.
- **Eval (§11):** adicionar casos:
  "recibos dessa semana" → `get_receipts_report{from:2026-11-16,to:2026-11-22}`;
  "quanto recebi em outubro" → `{from:2026-10-01,to:2026-10-31}`;
  "recibos do mês comparado ao passado" → `compare_previous:true`;
  "recibos do João" → continua `find_client` + `list_receipts` (não confundir).
- **Regressão:** não-assinante não vê a opção nem a tool.

### 14.8 Checklist da fase

- [ ] Soma/contagem/variação só no usecase (P2)
- [ ] Firestore só em `ReceiptRemoteDatasource` (P3)
- [ ] `ReceiptRepository.budgetId` intocado pelo relatório
- [ ] Regras + índice `collectionGroup` publicados antes do release
- [ ] `ARCHITECTURE.md` §20.3/§20.4 atualizados com a tool e os arquivos
- [ ] Custo: 1 leitura de coleção por sessão (cache); logar `usage` como os outros turnos

### 14.9 Preparação para a Fase 10 — Saldo do orçamento (total − pagamentos)

A Fase 9 é desenhada para que a Fase 10 seja **só um usecase + uma tool**, sem
consulta nova nem regra duplicada.

**Regra da Fase 10:**

```
saldo = totalOrçamento − Σ paid (pagamentos de todos os recibos do orçamento)
```

- `totalOrçamento` vem da mesma regra que o PDF/tela usam hoje (itens − desconto
  + acréscimos, se houver). **Não recalcular no chat**: reusar o usecase/getter
  do módulo `budget` que já produz o total exibido. Se ele estiver em VM,
  extrair para usecase primeiro (débito técnico, igual ao do Dashboard no §9).
- `paid` vem **do mesmo `ReceiptLedger`** da Fase 9, não de `VALORTOTAL`.
- Saldo negativo = pago a mais. O usecase marca como `overpaid` (não bloqueia),
  coerente com o aviso de `CreateReceiptForBudgetUseCase`.
- Status: `quitado` (saldo ≤ 0), `parcial` (0 < pago < total), `emAberto`
  (pago = 0). É um **valor calculado**, nunca persistido, e o label vem das strings.

**O que a Fase 9 já deixa pronto:**

| Peça da Fase 9 | Uso na Fase 10 |
|----------------|----------------|
| `ReceiptLedgerRepository` + cache/`invalidate()` | Fonte única de "quanto foi pago" por orçamento |
| `LedgerReceipt.paid` | Soma direta por `budgetId` |
| Nomes `issued`/`paid` no payload | Modelo e cards já conhecem os termos |
| Consulta `collectionGroup('PAGAMENTOS')` + regras/índices | Nada novo no Firestore |

**Entregas da Fase 10 (resumo):**

- `receipt/domain/usecase/get_budget_balance_usecase.dart`: `(budgetId)` →
  `BudgetBalance{budgetId, cliente, total, paid, balance, state}`.
- `receipt/domain/usecase/list_open_balances_usecase.dart`: todos os orçamentos
  com `balance > 0`, ordenados por saldo (≤ 20 ao modelo, lista completa na UI).
- Tool `get_budget_balance(budget_id?)` (sem id = lista de saldos em aberto).
- `ListReceiptsByBudgetUsecase` e `create_receipt` passam a usar o
  `GetBudgetBalanceUseCase` para o "saldo restante" do preview, para que haja
  **uma só fórmula de saldo** no app.
- Card `chat_budget_balance_card.dart` (total, pago, saldo e barra de progresso).
- Opcional: `GetReceiptsReportUseCase` ganha `openBalanceTotal` (soma dos
  saldos em aberto dos orçamentos do período).

> **Regra para a Fase 9 não travar a 10:** nenhum cálculo de "pago" fora do
> `ReceiptLedger`, e nenhum campo novo gravado no Firestore.

---

## 15. Fase 11 — Comprovantes de pagamento pelo chat (só assinantes)

> **Status (2026-11-20):** código Flutter implementado (módulo `payment_proof`,
> "+", galeria, prévia, fluxo `proof*` com "Voltar ao menu", lista no menu do
> orçamento, intent filters Android). **Pendente:** criar o target *Share
> Extension* no Xcode (arquivos já em `ios/ShareExtensionTemplate/`), registrar o App
> Group `group.com.housestudio.oflite.share`, publicar regras do Firestore e do
> Storage, tool `start_flow(attach_payment_proof)` e teste em aparelho real.
> Desvio do plano: fechar o modal de orçamentos **não** cancela o envio; o botão
> "Selecionar orçamento" continua ativo (e "Voltar ao menu" descarta).

> Referência visual: o painel de anexos do WhatsApp (grade com Fotos, Câmera,
> Documento…) e a tela de seleção de fotos com miniaturas, contador no botão de
> enviar e campo "Adicione uma legenda…".

### 15.1 Objetivo

O assinante envia **comprovantes de pagamento** (foto ou PDF) pelo chat e os
vincula a um orçamento. Cada orçamento ganha uma lista **Comprovantes**, igual à
de **Recibos** que já existe, onde dá para ver cada arquivo.

### 15.2 Regras de negócio

| # | Regra | Onde fica |
|---|-------|-----------|
| R1 | **Só assinantes.** O "+" e o recebimento por compartilhamento só funcionam com `ChatMode.aiAssistant` (decidido por `CheckAiAccessUseCase`, §2). Free: nada muda (P7). Free que compartilha um arquivo pelo sistema vê a tela de assinatura. | `CheckAiAccessUseCase` (reuso) |
| R2 | **Por envio:** até **2 imagens** OU **1 documento PDF**. A galeria bloqueia a 3ª foto. | `ValidateProofAttachmentsUseCase` |
| R3 | **Por orçamento:** no máximo **15 comprovantes**. Ao escolher o orçamento, o usecase confere `count + novos ≤ 15`. Se passar, o chat avisa e oferece escolher outro orçamento. Cada imagem de um envio de 2 fotos conta como 1 comprovante. | `CreatePaymentProofUseCase` |
| R4 | **Nome obrigatório.** Sem nome não salva. A **legenda** enviada com o arquivo vira o nome (não pergunta de novo). | `CreatePaymentProofUseCase` + `ParseMoneyInputUseCase.caption` |
| R5 | **Valor obrigatório** (`> 0`), aceita `1.234,56`, `1234.56`, `R$ 500`. Se a legenda trouxer o valor (`"R$ 500"` ou `"Pix entrada R$ 500"`), ele é usado e a pergunta é pulada. | `ParseMoneyInputUseCase` + `CreatePaymentProofUseCase` (`PaymentProofValueRequired`) |
| R6 | **Tipos aceitos:** `jpg`, `jpeg`, `png`, `heic` (convertido para jpg) e `pdf`. PDF até **10 MB**. Imagens são comprimidas para JPG (lado maior até 2048 px, qualidade caindo de 80 até 25) até ficarem com **no máximo 8 MB** antes do upload. | `ValidateProofAttachmentsUseCase` + `ProofFileLocalDatasource` |
| R11 | **Permissões no início.** Ao abrir o chat no modo IA, pede câmera + fotos. Recusado → snack "Não consigo seguir sem liberação da permissão." (de novo ao tocar no "+"). | `PickProofAttachmentsUseCase.requestPermissions` + VM |
| R7 | **Data e hora do salvamento** ficam gravadas (`CRIADOEM`, Timestamp) e aparecem na lista. O ID do documento é o timestamp em ms, igual aos recibos. | `CreatePaymentProofUseCase` |
| R8 | O fluxo de comprovante é **determinístico** (perguntas fixas, botões). **Não chama a LLM**, por isso não gasta cota e não consome o limite diário (§8). | VM + usecases |
| R10 | **Toda etapa tem "Voltar ao menu".** Cada mensagem do bot no fluxo (modal de orçamento, nome, valor, limite atingido, erro, sucesso) mostra o botão padrão **Voltar ao menu** (`menuBackLabel`, o mesmo de recomeçar o chat). Ao tocar: descarta o `PaymentProofDraft` (nada vai para o Storage/Firestore), limpa os passos `proof*` e mostra o menu principal. O ícone de recomeçar (`restartTooltip`) na barra superior faz o mesmo. Toque não chama a LLM (P4/R8). | VM (`cancelProofFlow`) |
| R9 | Valores gravados fixos (P5): `TIPO` = `IMAGEM` / `PDF`. Só o label é traduzido. | entity |

### 15.3 Fluxo completo no chat

```
[Usuário toca "+" na barra do chat]
  └─ Abre o painel de anexos em MODAL (navigator raiz, cobre a tab bar):
       [Fotos]   [Câmera]   [Documento]
        │          │           │
        │          │           └─ file_selector (pdf) → 1 arquivo → prévia
        │          └─ image_picker(camera) → 1 foto → prévia
        └─ Seletor em modal de 75% da tela (grade, abas Fotos/Álbuns,
           máx. 2, número da ordem na bolinha), barra embaixo com
           [miniatura ✎ recortar] [Adicione uma legenda…] [enviar ²]
  Prévia (câmera/PDF/compartilhamento): arquivo grande, [✎ recortar] à
  esquerda da legenda (imagem atual), enviar com contador.
[Usuário toca enviar]
  └─ Bolha do usuário: imagem(ns) (ou card do PDF) + legenda
  └─ Legenda → nome e/ou valor (ParseMoneyInputUseCase.caption)
  └─ bot: "A qual orçamento…?" [Selecionar orçamento] [Voltar ao menu]
       → modal de orçamentos (fechar sem escolher mantém o botão ativo)
       └─ escolheu → CheckProofLimitUseCase
            ├─ limite → "Esse orçamento já tem 15…" [Escolher outro] [Voltar ao menu]
            └─ ok → pergunta só o que falta:
                 ├─ sem nome  → "Qual o nome do comprovante?"   [Voltar ao menu]
                 ├─ sem valor → "Qual o valor do comprovante?"  [Voltar ao menu]
                 │               inválido → "Não entendi o valor. Ex.: 150,00"
                 └─ completo  → salva
                      ├─ sucesso → "Comprovante salvo com sucesso ✅"
                      │            [Ver comprovantes] [Voltar ao menu]
                      └─ erro    → "Não consegui salvar…" [Tentar de novo] [Voltar ao menu]
```

- A pergunta "Quer digitar o valor?" (Sim/Não) **saiu**: o valor é obrigatório.
- **Durante o fluxo**, o texto digitado vai para a state machine (passos
  `proof*`) e **não** para o agente, igual ao handoff do §3.3.
- **Agente (pendente):** `start_flow(flow: attach_payment_proof, budget_id?)`
  abriria o painel de anexos. O agente nunca recebe a imagem (custo e LGPD).

**Novos passos em `ChatFlowStep`:** `proofSelectBudget`, `proofAskName`,
`proofAskValue`, `proofSaving`, `proofSaveError`, `proofDone`. O rascunho fica em
`PaymentProofDraft{files, caption, budgetId, name, value}` no VM, só em memória.

### 15.4 Receber pelo compartilhamento do sistema (Android e iOS)

O app aparece na folha de compartilhamento para **imagens e PDF**.

| Plataforma | Configuração |
|-----------|--------------|
| Android | `AndroidManifest.xml`: `intent-filter` com `ACTION_SEND` (`image/*`, `application/pdf`) e `ACTION_SEND_MULTIPLE` (`image/*`) na `MainActivity`, `launchMode="singleTask"`. |
| iOS | **Share Extension** (target novo `ShareExtension` no Xcode) + **App Group** (`group.<bundle>.share`) nos dois targets. `NSExtensionActivationRule` aceita até 2 imagens e 1 PDF. Adicionar o URL scheme do pacote em `Info.plist`. Ajustar o Podfile para o target da extensão. |

- Pacote: `receive_sharing_intent` (Android e iOS, cobre `SEND`/`SEND_MULTIPLE`
  e Share Extension). Uso **só** no datasource.
- `SharedMediaRemoteDatasource` (módulo `chat_assistant`) expõe `initialMedia()`
  e `mediaStream()` → lista de `{path, mimeType}`.
- `ReceiveSharedProofUseCase`: valida com `ValidateProofAttachmentsUseCase`
  (mais de 2 imagens → usa as 2 primeiras e avisa), checa o acesso (R1) e
  devolve o rascunho.
- **Navegação:** app aberto ou frio → se não estiver logado, guarda o rascunho e
  segue após o login. Logado e assinante → abre o chat já na **tela de prévia**
  (mesma do passo "Fotos"), e o fluxo segue igual ao §15.3. Não assinante →
  tela de assinatura.

### 15.5 Dados — Firestore e Storage

```
Firestore: EMPRESAS/{uid}/USERS/{uid}/ORCAMENTOS/{budgetId}/COMPROVANTES/{id}
{
  "NOME":       "Pix entrada",            // obrigatório
  "VALOR":      500.0,                    // opcional (null = sem valor)
  "COMENTARIO": "pago pela esposa",       // opcional (legenda)
  "TIPO":       "IMAGEM" | "PDF",         // valor fixo (P5)
  "ARQUIVO":    "https://...",            // download URL do Storage
  "CAMINHO":    "comprovantes/{uid}/{budgetId}/{id}.jpg",  // para excluir depois
  "TAMANHO":    183422,                   // bytes
  "CRIADOEM":   Timestamp,                // data + hora do salvamento
  "ORIGEM":     "CHAT" | "COMPARTILHAMENTO"
}

Storage: comprovantes/{uid}/{budgetId}/{id}.{jpg|pdf}
```

- Envio de 2 fotos = **2 documentos** com o mesmo `NOME` e sufixo ` (1)`/` (2)`.
- Ordem de gravação: upload no Storage → grava o documento. Se o documento
  falhar, o usecase apaga o arquivo enviado (sem órfãos).
- `firestore.rules`: `COMPROVANTES` com leitura/escrita só quando o caminho é do
  `request.auth.uid`. **O limite de 15 é reforçado na regra** quando possível
  (contador `QTDCOMPROVANTES` no orçamento, via transação) — senão fica só no
  usecase (decisão no início da fase).
- `storage.rules`: `comprovantes/{uid}/**` só para o dono; `contentType` imagem
  ou pdf; `size < 10 MB`.
Regras para colar no console (Firestore e Storage não estão versionados no repo):

```
// firestore.rules (dentro de match /databases/{database}/documents)
match /EMPRESAS/{uid}/USERS/{uid2}/ORCAMENTOS/{budgetId}/COMPROVANTES/{id} {
  allow read, delete: if request.auth.uid == uid;
  allow create: if request.auth.uid == uid
    && request.resource.data.NOME is string && request.resource.data.NOME.size() > 0
    && request.resource.data.TIPO in ['IMAGEM', 'PDF'];
}

// storage.rules
match /comprovantes/{uid}/{budgetId}/{file} {
  allow read, delete: if request.auth.uid == uid;
  allow write: if request.auth.uid == uid
    && request.resource.size < 10 * 1024 * 1024
    && (request.resource.contentType.matches('image/.*')
        || request.resource.contentType == 'application/pdf');
}
```

- Recibos e comprovantes são **independentes**: comprovante **não** entra no
  `ReceiptLedger` nem no "pago" da Fase 10 (o valor é informativo). Se um dia
  entrar, só o agregador muda.

### 15.6 Arquivos (UseCase → Repo → DataSource)

Novo módulo **`payment_proof`** (o dono da regra), no mesmo formato de `receipt`:

```
lib/modules/payment_proof/
├── payment_proof_binds.dart
├── data/
│   ├── datasource/payment_proof_remote_datasource.dart   # Firestore COMPROVANTES (CRUD + count)
│   ├── datasource/payment_proof_storage_datasource.dart  # Firebase Storage (upload/delete)
│   ├── datasource/proof_file_local_datasource.dart       # compressão de imagem, heic→jpg, tamanho
│   ├── model/payment_proof.dart                          # fromJson/toJson com as chaves acima
│   └── repository/payment_proof_repository_impl.dart
├── domain/
│   ├── entity/payment_proof_type.dart                    # enum IMAGEM/PDF (valor fixo)
│   ├── entity/payment_proof_draft.dart                   # arquivos + legenda + budgetId + nome + valor
│   ├── repository/payment_proof_repository.dart
│   └── usecase/
│       ├── validate_proof_attachments_usecase.dart       # R2, R6
│       ├── check_proof_limit_usecase.dart                # R3 (count do orçamento)
│       ├── create_payment_proof_usecase.dart             # R3, R4, R7: upload + gravação + rollback
│       ├── list_payment_proofs_usecase.dart              # ordem CRIADOEM desc
│       └── delete_payment_proof_usecase.dart             # apaga doc + arquivo
└── presenter/
    ├── strings/payment_proof_pt_string.dart (+ en)
    ├── payment_proof_list/                               # tela (aba "Comprovantes" do orçamento)
    │   ├── payment_proof_list_view.dart
    │   ├── payment_proof_list_view_model.dart
    │   └── components/payment_proof_tile.dart            # padrão do card de orçamento
    └── payment_proof_viewer/                             # imagem em tela cheia (zoom)
        ├── payment_proof_viewer_view.dart
        └── payment_proof_viewer_view_model.dart
```

Alterações:

| Arquivo | Mudança |
|---------|---------|
| `chat_assistant/presenter/chat_assistant/components/chat_input_bar.dart` | Botão **"+"** à esquerda (só no modo IA). Alterna teclado ↔ painel. |
| `chat_assistant/presenter/chat_attachment_panel/` (**modal-tela**, §19 da arquitetura) | Grade Fotos/Câmera/Documento. View + VM + `components/chat_attachment_option.dart`. |
| `chat_assistant/presenter/chat_media_picker/` (**tela**) | Grade de miniaturas com seleção (máx. 2, bolinha com número), abas Fotos/Álbuns, tela de prévia com legenda e botão enviar com contador (print 2). Usa `photo_manager` (listar galeria) — `image_picker` não permite essa UI. |
| `chat_assistant/data/datasource/device_media_datasource.dart` | Único lugar com `photo_manager`, `image_picker` (câmera) e `file_selector` (PDF). |
| `chat_assistant/data/datasource/shared_media_remote_datasource.dart` | `receive_sharing_intent` (§15.4). |
| `chat_assistant/domain/usecase/receive_shared_proof_usecase.dart` | §15.4. |
| `chat_assistant/domain/entity/chat_message_entity.dart` | **+** `ChatMessageType.attachment` (payload: `files[{path,type,name}]`, `caption`). |
| `chat_assistant/presenter/.../components/chat_attachment_bubble.dart` | Bolha do usuário com 1–2 miniaturas (ou card PDF) + legenda + hora. Toque abre o visualizador. |
| `chat_assistant_view_model.dart` | Passos `proof*` (§15.3), `PaymentProofDraft`, métodos `openAttachments`, `onAttachmentsSent`, `onProofBudgetSelected`. Os handlers existentes **não mudam**. Avaliar extrair para `ChatProofFlowController` pelo tamanho do VM. |
| `chat_assistant/domain/usecase/dispatch_agent_tool_usecase.dart` | `start_flow` ganha `attach_payment_proof`. |
| `budget` (tela de detalhe/menu do orçamento) | Nova opção **Comprovantes** ao lado de **Recibos**, com contador `x/15`. |
| `pdf` | O `SfPdfViewer` atual abre o PDF por URL (`SfPdfViewer.network`) ao tocar num comprovante PDF. |
| `android/app/src/main/AndroidManifest.xml` | Intent filters (§15.4); permissões de câmera e `READ_MEDIA_IMAGES`. |
| `ios/Runner/Info.plist` + `ios/ShareExtension/` | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, Share Extension, App Group. |
| `pubspec.yaml` | `photo_manager`, `file_selector`, `receive_sharing_intent`, `flutter_image_compress` (versões estáveis mais recentes). |
| `firestore.rules`, `storage.rules` | §15.5. |
| `main.dart` / `main_tab` | Escuta `mediaStream()` após login e navega para o chat (§15.4). |

> **Débito técnico encontrado:** hoje `image/presenter/image_edit_view_model.dart`
> usa `firebase_storage` direto no VM, violando "chamada externa só no
> DataSource". A Fase 11 não copia esse padrão; migrar o upload do logo para um
> datasource é tarefa separada.

### 15.7 Lista de comprovantes (dentro do orçamento)

- Mesmo padrão visual do card da lista de orçamentos (avatar com ícone do tipo,
  título, subtítulo, valor à direita, chip à direita embaixo).
- **Título:** `NOME`. **Subtítulo:** `dd/MM/yyyy às HH:mm` (de `CRIADOEM`, fuso
  local). **Direita:** valor em moeda local, ou "Sem valor". **Chip:** `Imagem`/`PDF`.
  Comentário em 1 linha, se houver.
- Cabeçalho com `x de 15 comprovantes`. Ordem: mais recente primeiro.
- **A lista não baixa imagens** (só ícone do tipo), para poupar dados do
  cliente e leituras do Storage.
- **Rodapé** (`PaymentProofTotalBar`, mesmo visual do total dos itens do
  orçamento): quantidade de comprovantes e soma dos valores (soma no
  `ListPaymentProofsUseCase`).
- **Toque:** modal de 80% (`PaymentProofDetailSheet`) com a imagem no topo
  (baixada só agora) e nome, valor, data/hora, tipo e comentário abaixo. Tocar
  na imagem abre tela cheia com zoom; PDF mostra "Abrir PDF" → visualizador do app.
- Menu `⋮`: Compartilhar (`share_plus`) e Excluir (com confirmação, §19). Excluir
  libera vaga no limite de 15.
- Estado vazio: "Nenhum comprovante ainda. Envie pelo chat 📎".
- Botão "Adicionar comprovante" na lista abre o chat já no painel de anexos com o
  orçamento escolhido (pula o modal).

### 15.8 Strings (pt + en)

`attachPhotos` "Fotos", `attachCamera` "Câmera", `attachDocument` "Documento",
`captionHint` "Adicione uma legenda…", `proofAskName` "Qual o nome do comprovante?",
`cropTitle` "Recortar imagem", `permissionDenied` "Não consigo seguir sem liberação da permissão.",
`menuBackLabel` "Voltar ao menu" (reuso, já existe), `proofAskValue` "Qual o valor do comprovante?",
`proofInvalidValue` "Não entendi o valor. Ex.: 150,00", `proofSaved`
"Comprovante salvo com sucesso", `proofLimitReached` "Esse orçamento já tem 15
comprovantes.", `proofMaxPhotos` "Você pode enviar até 2 fotos.", `proofTooBig`
"Arquivo maior que 10 MB.", `proofsTitle` "Comprovantes", `proofNoValue` "Sem valor",
`proofDateTime` "{data} às {hora}".

### 15.9 Testes

- **Unit:** `ValidateProofAttachmentsUseCase` (3 fotos, foto + PDF, tipo inválido,
  > 10 MB); `CheckProofLimitUseCase` (14 + 2 = bloqueia, 13 + 2 = ok);
  `CreatePaymentProofUseCase` (sem nome → erro; sem valor; com valor; 2 fotos =
  2 docs; falha no Firestore apaga o arquivo do Storage); parser de valor
  (legenda "R$ 500" → valor, "pago ontem" → comentário).
- **VM:** sequência de passos `proof*` com repos fake (nome/valor vindos da legenda, valor inválido, Voltar ao menu,
  cancelar o modal, "Voltar ao menu" em cada passo descarta o rascunho sem upload, limite atingido, erro e "Tentar de novo"); nenhuma chamada
  ao `ChatAiRepository` durante o fluxo (R8).
- **Manual:** compartilhar 1 e 2 fotos e 1 PDF a partir da Galeria/Arquivos no
  Android e no iOS (app aberto e fechado); câmera; free não vê o "+".
- **Regressão:** usuário free tem o chat idêntico ao de hoje.

### 15.10 Checklist da fase

- [ ] "+" e compartilhamento só para assinantes; free sem mudança
- [ ] Máx. 2 imagens por envio; máx. 15 por orçamento (usecase + regra)
- [ ] Nome obrigatório; valor opcional; legenda vira comentário
- [ ] `CRIADOEM` com data e hora, exibido na lista
- [ ] Firestore/Storage/pickers/share intent só em datasource (P3)
- [ ] Upload com rollback (sem arquivo órfão)
- [ ] Fluxo sem LLM (R8)
- [ ] Botão "Voltar ao menu" em todas as etapas, descartando o rascunho (R10)
- [ ] Share Extension iOS + intent filters Android testados em aparelho real
- [ ] Regras do Firestore e do Storage publicadas antes do release
- [ ] `ARCHITECTURE.md` §20 atualizado com o módulo `payment_proof`

---

## 16. Refatoração da tela do chat (View + ViewModel + strings por tela)

> **Status (2026-11-21):** plano — nada implementado ainda.
> **Regra nº 1: comportamento idêntico.** É refatoração pura: nenhuma
> mudança de fluxo, texto exibido, ordem de mensagens, valores persistidos
> (`step.name`, `payload`, `action`) ou navegação. **Nenhuma outra melhoria
> entra nesta fase** — o que for notado fora do escopo vai para uma nota
> no fim desta seção, não para o código.

### 16.1 Diagnóstico (hoje)

| Arquivo | Linhas | Problemas |
|---|---|---|
| `chat_assistant_view.dart` | 1023 | `_EditAwareInputBar` e `_ManualAddressForm` privados dentro da View (viola regra 10); `Color(0x…)`/`Colors.*` direto (regra 16); textos fixos (`'Assistente'`, `'online'`, `'Reiniciar conversa'`, `'Editar Logo'`, `'Erro ao compartilhar'`, `'Editando mensagem'`, `'Digite uma mensagem...'`, `'Bairro (opcional)'`, `'Confirmar endereço'`, `'CEP'`); decisões de fluxo na View (`switch` de `'SIM'/'Sim'/'NÃO'/'Não'` olhando `_vm.step`; checagem de assinante em `_openLogoEditFlow`; `getIt<UserRepository>`/`getIt<PdfRepository>`/`getIt<BudgetRepository>` chamados na View). |
| `chat_assistant_view_model.dart` | 2123 | `_sendText` (≈130 linhas) roteia todos os steps; CEP/endereço manual/correção (`_submitCep`, `_submitManualAddress`, `_cancelCorrectionAndConfirm`, `_savePdfAddress`) com regra de negócio; fluxo de comprovante (`_saveProof`, `onProofBudgetSelected`, `_handleProofText`); `handleAction` (≈100 linhas); validação/formatação de telefone; ≈46 textos fixos; `getIt<CepRepository>()` dentro do método e `SharePlus` chamado direto (chamada externa fora do DataSource). |
| `presenter/strings/chat_budget_pt_string.dart` | 481 | Um arquivo para 4 telas (chat, budget picker, media picker, proof preview). |
| `components/chat_input_bar.dart` | 81 | Já existe e parece não ser usado pela View (a View usa `_EditAwareInputBar`). Confirmar antes de mexer. |

### 16.2 Estrutura alvo

```
modules/chat_assistant/presenter/
├── enum/chat_flow_step_enum.dart                 # sem mudança
├── chat_assistant/
│   ├── chat_assistant_view.dart                  # só commands, navegação e modais (precisam de context)
│   ├── chat_assistant_view_model.dart            # estado + orquestração; regras viram usecases
│   ├── strings/chat_assistant_pt_string.dart     # textos SÓ desta tela
│   └── components/
│       ├── chat_app_bar.dart                     # avatar + "Assistente/online" + reiniciar
│       ├── chat_edit_aware_input_bar.dart        # ex-_EditAwareInputBar (cópia fiel)
│       ├── chat_editing_banner.dart              # faixa "Editando mensagem"
│       ├── chat_manual_address_form.dart         # ex-_ManualAddressForm (cópia fiel)
│       ├── chat_message_list.dart                # ListView + typing indicator
│       └── … (os já existentes)
├── chat_budget_picker/
│   └── strings/chat_budget_picker_pt_string.dart
├── chat_media_picker/
│   └── strings/chat_media_picker_pt_string.dart
└── chat_proof_preview/
    └── strings/chat_proof_preview_pt_string.dart
```

- **Strings por tela**: cada pasta de tela tem `strings/{tela}_pt_string.dart`
  com `static String get …`. O `chat_budget_pt_string.dart` é dividido;
  string usada por mais de uma tela fica na tela dona do contexto
  (normalmente `chat_assistant`). **O texto não muda nem uma vírgula** — só o
  lugar. Strings comparadas com valores persistidos/`action`
  (`'SIM'`, `'Confirmar endereço'`, `aiConfirmLabel`…) ficam como estão até
  existir chave estável (Regra Zero do i18n: label traduz, valor não).
- **`_build…` na View** só para pedaços pequenos usados apenas nessa tela
  (ex.: `_buildAvatar()`, `_buildInputArea()` que escolhe form × barra).
  Widget com mais de ~40 linhas ou com estado → `components/`, um por arquivo.
- **Cores**: os `Color(0x…)` dos componentes extraídos passam a usar
  constantes de `colors.dart` **com o mesmo valor hex** (adicionar se faltar).

### 16.3 O que fica na View × vai para a ViewModel

**View pode:** executar commands (`_vm.xCommand.execute`), `Navigator.push`,
abrir modal/`showModalBottomSheet`, `ScaffoldMessenger`, alertas que pedem
`context`, controlar `ScrollController`/`FocusNode`.

**Vai para a ViewModel (ou usecase):**

| Hoje na View | Destino |
|---|---|
| `switch` `'SIM'/'Sim'/'NÃO'/'Não'` + `_vm.step` em `_handleAction` | `vm.resolveAction(action)` devolve um `ChatUiEffect` (enum: `openComments`, `openBudgetItems`, `none`…) e a View só executa o efeito de tela |
| `_openLogoEditFlow` checando `autoRenewing` e `fetchInformationEnterprise` | `vm.prepareLogoEdit()` → `({bool needsSubscription, OwnerPdf owner})` |
| `getIt<BudgetRepository>().clearSelectBudget()` | `vm.onBudgetPdfClosed()` |
| regra `enabled` do input (`step != askAddress …`) | getter `vm.inputEnabled` |
| `_showProofIssue` (decide aviso × erro e qual texto) | `vm.proofIssueMessage(v)` → `({bool warning, String? msg})`; View só mostra |
| `_vm.shareErrorMessage ?? 'Erro ao compartilhar'` | VM já entrega a mensagem final |
| `onSend` (trim/clear/execute) | `vm.submitInput()` |

**Estados:** todo método novo da VM que muda campo termina com
`notifyListeners()` (ou roda dentro de command, que já notifica). Checklist
por PR: grep de cada `_campo =` e confirmar notificação.

### 16.4 UseCases novos (regras saindo da ViewModel)

Todos em `chat_assistant/domain/usecase/`, sem `BuildContext`, retornando
`Result`/record. A VM continua dona do estado e só aplica o resultado.

| UseCase | Sai de | Responsabilidade |
|---|---|---|
| `RouteChatTextUsecase` | `_sendText` (cadeia de `if/else`) | Função pura: `(step, aiMode, text, mainMenuOptions)` → `ChatTextRoute` (enum: `backToMenu`, `proof`, `reports`, `findBudgetPrompt`, `findBudget`, `ai`, `mainMenu`, `priceList`, `pdfEditConfirmEntry`, `pdfEdit`, `pdfField`, `pdfConfirm`, `username`, `usernameResult`, `logo`, `clientName`, `clientPhone`, `hasCep`, `cep`, `none`). A VM vira um `switch` de uma linha por rota. **Mesma ordem de prioridade dos `if`s atuais** (teste de tabela cobrindo cada step). |
| `ValidateClientPhoneUsecase` | `_isValidPhone`, `_normalizePhone`, `_tryFormatPhone` | Validar/normalizar/formatar telefone. |
| `LookupChatCepUsecase` | `_submitCep` | Limpar CEP, validar 8 dígitos, buscar via `CepRepository`, devolver `invalid` / `notFound` / `found(address mascarado)`. Remove `getIt<CepRepository>()` do método. |
| `SaveChatAddressUsecase` | `_submitManualAddress`, `_confirmCepAddress`, `_cancelCorrectionAndConfirm` | Montar endereço e gravar no rascunho do orçamento. |
| `SavePdfAddressUsecase` | `_savePdfAddress` | Buscar `OwnerPdf`, aplicar campos, salvar. |
| `HandleProofTextUsecase` | `_handleProofText` | Validar nome/valor do comprovante → próximo passo. |
| `SaveChatProofUsecase` | `_saveProof` (+ checagem de `fits` de `onProofBudgetSelected`) | Gravar comprovante via repo do módulo `payment_proof`. |
| `ShareTextUsecase` (módulo `core/share_link`) | `SharePlus.instance.share` em `handleAction` | Compartilhamento sai da VM para o core (DataSource). |

`_sendText` alvo (≈30 linhas): edição de mensagem → envia mensagem do
usuário (payload `editableField` igual) → `route = _routeText(...)` →
`switch (route)` chamando os handlers existentes. O texto
`'Telefone inválido…'` e `'Erro ao processar: $e'` vão para
`ChatAssistantStrings`.

### 16.5 Fases (cada uma é um PR que compila e roda igual)

1. **Strings** — dividir `chat_budget_pt_string.dart` por tela e mover os
   literais da View/VM/componentes. Só troca de referência.
2. **Componentes** — extrair `_EditAwareInputBar`, `_ManualAddressForm`,
   app bar e lista para `components/` (cópia fiel, mesmos parâmetros);
   cores para `colors.dart`; checar `chat_input_bar.dart`.
3. **View enxuta** — mover decisões da §16.3 para a VM.
4. **UseCases** — um usecase por vez (§16.4), começando por
   `RouteChatTextUsecase` e `ValidateClientPhoneUsecase` (puros, fáceis de
   testar), depois CEP/endereço, comprovante, share. Registrar em
   `chat_assistant_binds.dart`.
5. **Remover acessos fora da arquitetura** — nenhum `getIt<…Repository>()`
   na View, nenhum SDK externo na VM (SSoT, `ARCHITECTURE.md` §21).

**Verificação por fase:** `flutter analyze` limpo; testes existentes verdes;
teste de tabela do `RouteChatTextUsecase`; roteiro manual: menu padrão
(orçamento completo com CEP, sem CEP, endereço manual, correção, edição de
nome/telefone, comentários, link/PDF), lista de preços, edição de PDF,
nome de usuário, logo, modo IA (pergunta livre, confirmação de escrita,
falha → modo padrão), comprovante (galeria, câmera, documento,
compartilhamento), encontrar/duplicar orçamento, recibos, "0" volta ao menu.

### 16.6 Futuro — conversas salvas no celular (estilo WhatsApp)

> Só estrutura; **não implementar nesta fase**.

Hoje cada conversa é uma sessão no Firestore
(`ChatBudgetRemoteDataSource.createSession/saveMessage/fetchMessages`) e o
chat reinicia a cada abertura. O destino é uma **lista de conversas**
persistida no aparelho:

- **Fonte única da verdade (SSoT):** o `ChatBudgetRepository` é o dono das
  conversas. View/VM nunca leem banco local nem Firestore direto; a lista de
  mensagens exibida é sempre a do repositório (`ChangeNotifier`).
- **Dados:** novo `ChatLocalDataSource` (único que conhece o banco local) com
  `conversations` (`id`, `title`, `lastMessage`, `updatedAt`, `flowStep`) e
  `messages` (`id`, `conversationId`, `role`, `type`, `text`, `payload`,
  `timestamp`). O Firestore vira, se mantido, sincronização feita **pelo
  repositório**, nunca pela tela.
- **Entidades:** `ChatConversationEntity` em `domain/entity/`; o
  `ChatMessageEntity` ganha `conversationId`.
- **UseCases:** `ListConversationsUsecase`, `OpenConversationUsecase`
  (restaura mensagens + `flowStep`), `StartConversationUsecase`,
  `DeleteConversationUsecase`.
- **Telas:** `presenter/chat_conversation_list/` (View + VM + `components/`
  + `strings/`) abrindo `ChatAssistantView(conversationId: …)`.
- **Compatibilidade:** `step.name`, `payload` e `action` já salvos são
  contrato — nunca renomear (Regra Zero). Botões de mensagens antigas
  restauradas continuam desabilitados por `isButtonsActive`.
