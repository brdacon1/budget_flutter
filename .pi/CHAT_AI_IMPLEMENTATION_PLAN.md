# Plano de Implementação — Chat Inteligente (LLM) com Gate de Assinatura

> **Projeto:** OFLite (App Flutter de Orçamentos + Firebase)  
> **Base:** `CHAT_ASSISTANT_SPEC.md` + `PROJECT_STRUCTURE.md`  
> **Arquitetura:** Clean Architecture (ponytail) + MVVM + ChangeNotifier + get_it  
> **Modelo LLM:** Gemini via Firebase AI Logic  

---

## 1. Visão Geral da Arquitetura Híbrida

```
┌────────────────────────────────────────────────────────────────────┐
│  USUÁRIO DIGITA: "busque orçamentos pendentes do cliente Silva"   │
└──────────────────────────────┬───────────────────────────────────────┘
                               │
         ┌─────────────────────▼─────────────────────┐
         │  ChatAssistantViewModel._onSubmit()     │
         │  (modificada — gate de assinatura)      │
         └─────────────────────┬─────────────────────┘
                               │
              ┌────────────────┴────────────────┐
              │                                 │
     ┌────────▼────────┐               ┌────────▼────────┐
     │  NÃO ASSINANTE  │               │   ASSINANTE     │
     │  UID.autoRenew  │               │   UID.autoRenew │
     │      = false    │               │      = true     │
     └────────┬────────┘               └────────┬────────┘
              │                                 │
     ┌────────▼────────┐               ┌────────▼────────┐
     │  Mantém fluxo     │               │  Processa via   │
     │  determinístico   │               │  LLM (Gemini)   │
     │  (bot WhatsApp)   │               │  + FunctionCall │
     │  — ZERO mudança   │               │                 │
     └───────────────────┘               │  1. Envia msg   │
                                         │  2. Recebe tool │
                                         │     ou texto    │
                                         │  3. Executa no│
                                         │     app         │
                                         │  4. Devolve     │
                                         │     resultado   │
                                         │  5. IA formata  │
                                         │     resposta    │
                                         └─────────────────┘
```

### Regra de Ouro
> **Não-assinantes não sentem absolutamente NADA.** O chat hoje continua exatamente igual. Assinantes ganham o modo inteligente.

---

## 2. Gate de Assinatura (Feature Flag por Usuário)

O app **já tem** o campo de assinatura no escopo global:

```dart
// lib/shared/common/constants/global_uid_user.dart
bool? autoRenewing = false;
```

O gate é consultado em **dois momentos**:

1. **Na inicialização do chat** (`initializeChat`): decide se mostra o bot clássico ou o assistente IA.
2. **A cada mensagem enviada**: reafirma o modo (evita troca no meio da conversa).

### Decisão de Modo

```dart
enum ChatMode { deterministic, aiAssistant }
```

- `deterministic` → state machine atual (`ChatFlowStep` + switch-case)
- `aiAssistant` → processamento via LLM com Function Calling

O modo é persistido apenas em memória durante a sessão do chat. Se o usuário sair e voltar, reavalia.

---

## 3. Novas Entidades, Repositories e UseCases

Todos os novos arquivos ficam dentro de `../lib/modules/chat_assistant`.

### 3.1 Entidades de Domínio (novos arquivos)

| Arquivo | Propósito |
|---------|-----------|
| `domain/entity/chat_tool_request_entity.dart` | Representa uma "tool" que a LLM pediu para executar. Campos: `toolName`, `arguments` (`Map<String, dynamic>`). |
| `domain/entity/chat_tool_result_entity.dart` | Resultado da execução de uma tool. Campos: `toolName`, `success` (`bool`), `data` (`Map<String, dynamic>?`), `errorMessage` (`String?`). |
| `domain/entity/chat_intent_entity.dart` | Enum de intenções detectadas localmente para rotear rápido sem gastar tokens: `createBudget`, `editPdf`, `priceList`, `changeUsername`, `searchBudgets`, `continueBudget`, `addProduct`, `unknown`. |

### 3.2 Contratos de Repository (novos arquivos)

| Arquivo | Propósito |
|---------|-----------|
| `domain/repository/chat_ai_repository.dart` | Interface com método: `Future<String> generateResponse(List<ChatMessageEntity> history, String userMessage, List<ChatToolDefinition> tools)`. Retorna texto da IA OU indica que há function calls pendentes. |
| `domain/repository/chat_tool_executor_repository.dart` | Interface para executar tools localmente. `Future<ChatToolResultEntity> execute(String toolName, Map<String, dynamic> args)`. |

> **Nota:** `ChatToolDefinition` é um DTO simples descrevendo cada tool (nome, descrição, parâmetros) no formato que a SDK do Gemini espera.

### 3.3 DataSource e RepositoryImpl (novos arquivos)

| Arquivo | Propósito |
|---------|-----------|
| `data/datasource/chat_ai_remote_datasource.dart` | Fala com Firebase AI Logic / Google AI SDK (**fonte externa**). Métodos: monta `GenerativeModel`, envia `generateContent`, recebe `response.functionCalls`. Retorna `Map<String, dynamic>`. NÃO conhece entities. |
| `data/repository/chat_ai_repository_impl.dart` | Converte Map ↔ Entity. Implementa `ChatAiRepository`. Traduz function calls do formato Gemini para `ChatToolRequestEntity`. |
| `data/repository/chat_tool_executor_repository_impl.dart` | Implementa `ChatToolExecutorRepository`. Orquestra a execução de cada tool chamando repositórios existentes (`BudgetRepository`, `PdfRepository`, etc.) e navegações da View. |

### 3.4 UseCases (novos arquivos)

| Arquivo | Propósito | Executa onde |
|---------|-----------|--------------|
| `domain/usecase/check_ai_access_usecase.dart` | Retorna `bool` baseado em `UID.autoRenewing ?? false`. | Antes de processar msg. |
| `domain/usecase/determine_chat_mode_usecase.dart` | Retorna `ChatMode` (deterministic ou aiAssistant). | `initializeChat` do VM. |
| `domain/usecase/classify_user_intent_usecase.dart` | Classifica a mensagem do usuário por regex/keyword em ~1ms. Se bater com fluxo existente (ex: "cadastrar produto"), retorna intent sem chamar LLM. Se `unknown`, vai pra LLM. | Antes da LLM. |
| `domain/usecase/build_system_prompt_usecase.dart` | Monta o system prompt com contexto do app (nome do usuário, dados do OwnerPdf, orçamentos recentes). Dica: cachear em memória. | A cada msg no modo IA. |
| `domain/usecase/process_ai_message_usecase.dart` | **Orquestrador mestre.** Recebe msg do usuário → classifica intent → se IA: monta system prompt + history → chama `ChatAiRepository` → recebe function calls → chama `ChatToolExecutorRepository` → devolve resultado para IA formatar → retorna texto final para exibir. | `aiAssistant` mode. |
| `domain/usecase/get_budgets_for_ai_usecase.dart` | Busca orçamentos para a tool `search_budgets`. Reutiliza `BudgetRepository`. Usa filtro local após `fetchBudgets()` (já que Firestore não suporta `where('customerName', contains: 'Silva')` de forma eficiente). | Dentro do tool executor. |

---

## 4. Ferramentas (Tools / Function Calling) Disponíveis para a LLM

A LLM nunca acessa o Firestore. Ela recebe estas definições e **pede** para o app executar:

### 4.1 Lista de Tools

| Tool (`function.name`) | Parâmetros | O que o app faz |
|------------------------|------------|-----------------|
| `search_budgets` | `status` (string, opcional), `clienteNome` (string, opcional), `periodo` (string: "hoje", "semana", "mes", "todos") | Busca no Firestore via `BudgetRepository.fetchBudgets()`. Filtra localmente por nome e período. Retorna lista resumida. |
| `get_budget_details` | `orcamentoId` (string) | Busca o orçamento e seus itens. Retorna resumo. |
| `create_budget` | `clienteNome` (string, obrigatório), `telefone` (string, opcional) | Inicia o fluxo determinístico de orçamento: `_setStep(ChatFlowStep.askClient)` + `_pendingClientName = clienteNome`. Se telefone veio, pula direto para `confirmClientData`. |
| `continue_budget` | `clienteNome` (string, opcional), `orcamentoId` (string, opcional) | Se `orcamentoId` informado → entra no fluxo desse orçamento (`askProducts`). Se `clienteNome` → mostra lista de orçamentos pendentes dele como `inlineButtons`. |
| `edit_pdf` | `campo` (string: "nome", "telefone", "email", "cnpj", "endereco", "logo"), `valor` (string, opcional) | Se `valor` veio, salva direto. Se não, roteia para o step do fluxo determinístico (`pdfEditMenu`, `pdfEditFieldInput`). |
| `price_list_manage` | `acao` (string: "ver", "cadastrar") | Se "cadastrar" → `pendingNavigation = 'open_product_creator'`. Se "ver" → `pendingNavigation = 'open_price_list'`. |
| `change_username` | `novoNome` (string, opcional) | Se `novoNome` → salva. Se não → roteia para fluxo existente. |
| `navigate_to_screen` | `tela` (string: "budget_list", "dashboard", "subscription") | Define `pendingNavigation` para a View abrir. |
| `explain_capabilities` | — | Retorna texto explicando o que o assistente pode fazer. |

### 4.2 Tool que NÃO existe (exemplo de escopo)

| Tool **não implementada** | Resposta da IA |
|---------------------------|----------------|
| `update_budget_status` | *"Ainda não consigo alterar o status de um orçamento existente por aqui. Vá até a lista de orçamentos para isso. Quer que eu te leve?"* |

---

## 5. Fluxos de Exemplo em Detalhe

### Fluxo A: Buscar Orçamentos (Query)

**Usuário digita:** `"mostre os orçamentos aprovados do cliente Silva esse mês"`

**Passo a passo:**

1. ViewModel recebe a mensagem.
2. Modo é `aiAssistant` (assinante).
3. Chama `ProcessAiMessageUsecase`.
4. UseCase monta system prompt + history.
5. Chama `ChatAiRepository.generateResponse(...)`.
6. Gemini retorna **function call** `search_budgets` com args: `{status: "APROVADO", clienteNome: "Silva", periodo: "mes"}`.
7. `ChatToolExecutorRepository` executa:
   - `BudgetRepository.fetchBudgets(forceRefresh: true)`
   - Filtra local: `customerName.contains("Silva")`, `status == "APROVADO"`, `data` dentro do mês atual.
   - Retorna JSON com 3 orçamentos.
8. Devolve resultado para Gemini.
9. Gemini formata: *"Encontrei 3 orçamentos aprovados do Silva este mês:\n\n1. Orçamento #123456 — R$ 1.200,00 — 15/01\n..."*
10. ViewModel exibe como `ChatMessageType.text`.

---

### Fluxo B: Criar Orçamento por Linguagem Natural

**Usuário digita:** `"quero criar um orçamento pro cliente João, telefone 11999998888"`

**Passo a passo:**

1. IA retorna function call `create_budget` com args: `{clienteNome: "João", telefone: "11999998888"}`.
2. `ChatToolExecutor` chama o fluxo existente:
   - `_pendingClientName = "João"`
   - `_pendingPhone = "(11) 99999-8888"`
   - `_createDraftAndGoToAddress(...)`
3. O bot responde **no mesmo fluxo existente**: *"Orçamento criado para João. Quer incluir o endereço? [SIM / NÃO]"*
4. A partir daqui, o usuário segue o fluxo determinístico normal (state machine).
5. A diferença: a LLM **saltou** o menu principal e já preencheu os dados.

---

### Fluxo C: Cadastrar Produto (Abrir Modal Existente)

**Usuário digita:** `"preciso cadastrar um novo produto na lista de preço"`

**Passo a passo:**

1. IA retorna function call `price_list_manage` com args: `{acao: "cadastrar"}`.
2. `ChatToolExecutor` define `pendingNavigation = 'open_product_creator'`.
3. View (`ChatAssistantView`) captura `pendingNavigation` no postFrame e abre:
   - `showProductPriceCreatorBottomModal(context, item: ProductPriceModel())`
4. IA exibe mensagem antes de abrir: *"Vou abrir o cadastro de produto pra você. Preencha os dados e volte aqui quando terminar! 🚀"`
5. Usuário volta do modal.
6. ViewModel chama `onProductCreatedFromChat()` (já existe!) que mostra o sucesso e volta ao menu.

> **Ponto chave:** Não reescrevemos o modal. A IA simplesmente dispara a navegação que o bot já fazia.

---

### Fluxo D: Continuar Orçamento (Selecionar + Inserir Produtos)

**Usuário digita:** `"Preciso continuar o orçamento do cliente Silva e adicionar mais produtos"`

**Passo a passo:**

1. IA retorna function call `continue_budget` com args: `{clienteNome: "Silva"}`.
2. `ChatToolExecutor` busca orçamentos pendentes (status != finalizado / recentes).
3. Se encontra 2 orçamentos do Silva:
   - ViewModel exibe `ChatMessageType.inlineButtons`:
     - `Orçamento #123 — Silva — R$ 800,00 — 20/01`
     - `Orçamento #124 — Silva — R$ 1.200,00 — 22/01`
4. Usuário toca em um.
5. ViewModel faz `selectBudget(id)` + `_setStep(ChatFlowStep.askProducts)` + mostra mensagem: *"Beleza! Vamos adicionar produtos ao orçamento #123."*
6. Botão de ação `open_products` aparece (igual ao fluxo atual).
7. Usuário escolhe os produtos na tela nativa (`BudgetListItemsView`).
8. Ao voltar, segue o fluxo normal (`reviewProducts` → comentários → share).

> **Ponto chave:** A IA `listou` e o usuário `selecionou`. Depois disso, entramos no state machine existente.

---

### Fluxo E: Resposta fora de escopo

**Usuário digita:** `"altere o status do orçamento 129922928 para aprovado"`

**Passo a passo:**

1. LLM não encontra tool `update_budget_status`.
2. System prompt instrui: "Se não houver tool, explique educadamente que não pode e sugira alternativa."
3. IA responde: *"Ainda não consigo alterar o status de um orçamento existente por aqui. Para isso, acesse a lista de orçamentos na tela inicial. Quer que eu te leve até lá?"*
4. Se usuário responder *"sim"*, IA chama `navigate_to_screen` com `{tela: "budget_list"}`.

---

## 6. Modificações nos Arquivos Existentes

### 6.1 `chat_assistant_view_model.dart` (modificações)

**Mudanças mínimas e cirúrgicas:**

- Adicionar dependências no construtor:
  ```dart
  final DetermineChatModeUsecase _determineMode;
  final ProcessAiMessageUsecase _processAiMessage;
  final ClassifyUserIntentUsecase _classifyIntent;
  ```

- Em `_initialize()`:
  ```dart
  Future<Result<void>> _initialize() async {
    // ... código existente ...
    
    final mode = await _determineMode();
    if (mode == ChatMode.aiAssistant) {
      await _showAiWelcomeMessage(); // Mensagem amigável da IA
    } else {
      // comportamento atual (menu numérico)
      final step = await _resetToMenuUsecase();
      _setStepFromName(step);
    }
    notifyListeners();
    return Result.ok(null);
  }
  ```

- Em `_sendText()`:
  ```dart
  Future<Result<void>> _sendText(String text) async {
    // ... validações existentes (trim, edit mode, etc.) ...
    
    if (_mode == ChatMode.aiAssistant) {
      // Modo inteligente
      final intent = await _classifyIntent(text);
      if (intent != UserIntent.unknown) {
        // Se classificou localmente como fluxo existente, executa direto
        await _executeIntentDirectly(intent, text);
        return Result.ok(null);
      }
      
      // Se não classificou, vai pela IA
      final aiResponse = await _processAiMessage(text, messages);
      await _handleAiResponse(aiResponse);
      return Result.ok(null);
    }
    
    // Modo determinístico — código EXISTENTE inalterado
    if (_step == ChatFlowStep.mainMenu) { ... }
    // ... resto do switch-case atual ...
  }
  ```

- Novo método `_executeIntentDirectly(intent, text)`:
  - Se `createBudget` + extrai nome/tel por regex → entra no fluxo existente (`askClient`/`askPhone`)
  - Se `priceList` → `pendingNavigation = 'open_price_list'`
  - Se `editPdf` → `_setStep(ChatFlowStep.pdfEditConfirmEntry)`
  - Se `changeUsername` → `_setStep(ChatFlowStep.changeUsername)`

### 6.2 `chat_assistant_view.dart` (modificações mínimas)

- No `build`, ao detectar `pendingNavigation`, adicionar novos cases se necessário:
  ```dart
  case 'open_budget_list': // para navigate_to_screen
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetListView()));
    break;
  case 'continue_budget':
    // abre BottomSheet com lista de orçamentos ou já navega para BudgetListItemsView
    break;
  ```

- O input bar permanece igual. A IA não precisa de UI diferente.

### 6.3 `chat_assistant_binds.dart` (novos registros)

```dart
// Domain
sl.registerLazySingleton<ChatAiRepository>(
  () => ChatAiRepositoryImpl(sl<ChatAiRemoteDataSource>()),
);
sl.registerLazySingleton<ChatToolExecutorRepository>(
  () => ChatToolExecutorRepositoryImpl(
    sl<BudgetRepository>(),
    sl<PdfRepository>(),
    sl<ChatBudgetRepository>(),
  ),
);

// DataSource
sl.registerLazySingleton<ChatAiRemoteDataSource>(
  () => ChatAiRemoteDataSource(),
);

// UseCases
sl.registerFactory<CheckAiAccessUsecase>(() => const CheckAiAccessUsecase());
sl.registerFactory<DetermineChatModeUsecase>(
  () => DetermineChatModeUsecase(sl<CheckAiAccessUsecase>()),
);
sl.registerFactory<ClassifyUserIntentUsecase>(
  () => const ClassifyUserIntentUsecase(),
);
sl.registerFactory<BuildSystemPromptUsecase>(
  () => BuildSystemPromptUsecase(sl<PdfRepository>()),
);
sl.registerFactory<ProcessAiMessageUsecase>(
  () => ProcessAiMessageUsecase(
    sl<ClassifyUserIntentUsecase>(),
    sl<BuildSystemPromptUsecase>(),
    sl<ChatAiRepository>(),
    sl<ChatToolExecutorRepository>(),
    sl<ChatBudgetRepository>(),
  ),
);

// ViewModel (factory — adicionar parâmetros)
sl.registerFactory<ChatAssistantViewModel>(
  () => ChatAssistantViewModel(
    // ... parâmetros existentes ...
    sl<DetermineChatModeUsecase>(),
    sl<ProcessAiMessageUsecase>(),
    sl<ClassifyUserIntentUsecase>(),
  ),
);
```

---

## 7. O System Prompt (Instrução para a LLM)

O system prompt é montado dinamicamente a cada mensagem. Ele dá contexto do app para a IA não alucinar.

```
Você é o Assistente Inteligente do OFLite, um app de orçamentos.
Dados do usuário logado:
- Nome: {UID.name}
- Empresa: {ownerPdf.empresa}

Contexto do app:
- Orçamentos têm status: PENDENTE, APROVADO, REJEITADO.
- IDs de orçamento são timestamps (ex: 1705257600000).
- A data do orçamento está no campo "data" (formato dd/MM/yyyy).

Regras:
1. Sempre responda em português do Brasil.
2. Quando o usuário pedir algo que não está nas tools disponíveis, explique educadamente que não pode e sugira uma alternativa.
3. Nunca invente dados. Se não souber, peça mais informações.
4. Para criar orçamentos, use a tool "create_budget" com cliente nome e telefone.
5. Para buscar dados, use ferramentas — não invente resultados.
6. Para continuar orçamentos pendentes, use "continue_budget".
7. Para editar informações do PDF (nome da empresa, telefone, CNPJ, etc.), use "edit_pdf".
8. Para cadastrar produtos ou ver lista, use "price_list_manage".
```

> **Cache:** O system prompt muda pouco. Ele pode ser invalidado quando `OwnerPdf` ou dados do usuário mudam.

---

## 8. Dependência Externa

Adicionar ao `../pubspec.yaml`:

```yaml
dependencies:
  # existentes...
  firebase_ai_logic: ^x.x.x  # Firebase AI Logic SDK (ou google_generative_ai se rodar direto)
```

> **Nota:** Firebase AI Logic é o recomendado pelo Firebase. Se não estiver disponível para Flutter, `google_generative_ai` funciona com API key do Gemini (gerenciada via Firebase). A lógica interna (DataSource) encapsula isso.

---

## 9. Cronograma de Implementação (Fases)

### Fase 1 — Estrutura Base e Gate de Assinatura (1–2 dias)
- [ ] Criar `CheckAiAccessUsecase` e `DetermineChatModeUsecase`
- [ ] Criar enum `ChatMode`
- [ ] Modificar `ChatAssistantViewModel._initialize()` para escolher modo
- [ ] Testar: assinante vê IA, não-assinante vê bot antigo (sem quebrar)

### Fase 2 — Classificador Local de Intenção (1 dia)
- [ ] Criar `ClassifyUserIntentUsecase`
- [ ] Implementar regex/keywords em português para os 7 intents principais
- [ ] Roteamento rápido: se identificar "criar orçamento", já entra no fluxo sem LLM
- [ ] Testar: frases comuns em PT-BR

### Fase 3 — Integração Firebase AI Logic (2 dias)
- [ ] Criar `ChatAiRemoteDataSource` (wrapping da SDK)
- [ ] Criar `ChatAiRepository` + `ChatAiRepositoryImpl`
- [ ] Definir tools (até 5 tools: `search_budgets`, `create_budget`, `price_list_manage`, `edit_pdf`, `navigate_to_screen`)
- [ ] Implementar `ProcessAiMessageUsecase` (loop básico: user → LLM → text response)
- [ ] Testar: mensagens simples no modo IA

### Fase 4 — Function Calling e Execução de Tools (2–3 dias)
- [ ] Criar `ChatToolRequestEntity` + `ChatToolResultEntity`
- [ ] Criar `ChatToolExecutorRepository` + `ChatToolExecutorRepositoryImpl`
- [ ] Implementar `search_budgets` (busca + filtro local)
- [ ] Implementar `create_budget` (integra com state machine existente)
- [ ] Implementar `price_list_manage` (dispara navegações existentes)
- [ ] Implementar `edit_pdf` (roteia para steps existentes)
- [ ] Testar: cenários de busca, criação e navegação

### Fase 5 — Continuar Orçamentos (1–2 dias)
- [ ] Implementar tool `continue_budget`
- [ ] Criar mensagem tipo `inlineButtons` que lista orçamentos para seleção
- [ ] Na seleção, entra no fluxo `askProducts` do orçamento escolhido
- [ ] Testar: "continuar orçamento do cliente X"

### Fase 6 — System Prompt Dinâmico e Polimento (1 dia)
- [ ] Implementar `BuildSystemPromptUsecase`
- [ ] Adicionar contexto de `OwnerPdf` e dados do usuário
- [ ] Afinar respostas fora de escopo (ex: alterar status)
- [ ] Adicionar tratamento de erro da LLM (timeout, rate limit)

### Fase 7 — Testes e Refinamento (2 dias)
- [ ] Testar ambos os modos (determinístico e IA)
- [ ] Testar transição: usuário assina no meio do uso (reinicia chat)
- [ ] Revisar custos de tokens (monitorar no console do GCP)
- [ ] Ajustar prompts se necessário

---

## 10. Lista Completa: Arquivos Novos vs. Modificados

### Arquivos NOVOS (todos em `../lib/modules/chat_assistant`)

```
domain/entity/
  chat_tool_request_entity.dart
domain/entity/
  chat_tool_result_entity.dart
domain/entity/
  chat_intent_entity.dart
domain/repository/
  chat_ai_repository.dart
domain/repository/
  chat_tool_executor_repository.dart
domain/usecase/
  check_ai_access_usecase.dart
domain/usecase/
  determine_chat_mode_usecase.dart
domain/usecase/
  classify_user_intent_usecase.dart
domain/usecase/
  build_system_prompt_usecase.dart
domain/usecase/
  process_ai_message_usecase.dart
data/datasource/
  chat_ai_remote_datasource.dart
data/repository/
  chat_ai_repository_impl.dart
data/repository/
  chat_tool_executor_repository_impl.dart
presenter/enum/
  chat_mode_enum.dart          # ← novo enum paralelo ao ChatFlowStep
```

### Arquivos MODIFICADOS

```
presenter/chat_assistant/chat_assistant_view_model.dart     # Gate + roteamento IA
data/repository/chat_budget_repository_impl.dart              # Se precisar de novos métodos (selectBudget)
presenter/chat_assistant/chat_assistant_view.dart             # Novos cases de navegação
chat_assistant_binds.dart                                    # Registro DI das novas classes
pubspec.yaml                                                 # Adicionar firebase_ai_logic
```

---

## 11. Considerações de Segurança e Custo

| Risco | Mitigação |
|-------|-----------|
| API key exposta no app | Usar Firebase AI Logic (gerencia keys server-side) ou Cloud Functions |
| Custo inesperado | Classificador local intercepta ~80% das mensagens sem LLM |
| LLM alucinando dados | System prompt instrui a usar tools. App valida tudo antes de executar. |
| Usuário manipulando prompts | Tools são hardcoded; LLM não executa SQL/Queries diretas |
| Orçamentos acessados por outro user | Reutiliza `BudgetRepository` que já valida `UID.user` |

---

> **Próximo passo:** Executar **Fase 1** (estrutura base e gate de assinatura) para validar que o bot determinístico continua intacto para não-assinantes.
