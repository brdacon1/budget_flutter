# Chat Assistant — Especificação Técnica & Roadmap LLM

> **Projeto:** oflite (App Flutter de Orçamentos + Firebase)  
> **Módulo:** `../lib/modules/chat_assistant`  
> **Versão:** 1.0 — Bot por State Machine (atual) | 2.0 — Híbrido com LLM (proposta)

---

## 1. O que é hoje

O `chat_assistant` é um **bot de fluxo determinístico** (não é inteligente). Ele guia o usuário por menus numerados e passos sequenciais para:

- Criar orçamentos (nome → telefone → endereço → produtos → compartilhamento)
- Consultar lista de preços
- Editar informações do PDF da empresa (nome, telefone, CNPJ, endereço, logo)
- Alterar nome de usuário

A experiência imita um bot de WhatsApp: mensagens de texto com botões inline e comandos por número (`1`, `2`, `0`).

---

## 2. Estrutura de Dados

### 2.1 Entidade Principal — `ChatMessageEntity`

```dart
class ChatMessageEntity {
  final String id;                        // Timestamp-based
  final ChatSender sender;                // bot | user | system
  final ChatMessageType type;             // text | action | productList | contactPicker | inlineButtons | image
  final String content;                   // Texto exibido na bolha
  final Map<String, dynamic>? payload;    // Metadados de UI (ações, imagem, dados editáveis)
  final DateTime timestamp;
}
```

| Campo | Propósito |
|-------|-----------|
| `sender` | Define alinhamento da bolha (esquerda/direita) e cor |
| `type` | Define widgets extras renderizados abaixo do texto |
| `payload['actions']` | Lista de strings para botões inline (`['SIM', 'NÃO']`) |
| `payload['action']` + `payload['label']` | Botão de ação única (`action: 'open_products'`) |
| `payload['editableField']` | Permite long-press para editar mensagens do usuário (`clientName`, `clientPhone`) |
| `payload['imageBase64'` / `imageUrl']` | Renderiza imagem no chat (logo da empresa) |

### 2.2 Script Configurável — `ChatScriptEntity`

Todas as mensagens do bot são externalizáveis em Firestore:

```
EMPRESAS/{uid}/CONFIG/CHAT_SCRIPT/DEFAULT
```

Campos: `welcomeMessage`, `askClientName`, `askPhone`, `askAddress`, `askProducts`, `finalMessage`, etc.

> **Fallback:** Se o documento não existir, usa textos em português hardcoded.

### 2.3 Estado da Conversa — `ChatFlowStep`

```dart
enum ChatFlowStep {
  idle, welcome, askClient, askPhone, confirmClientData,
  askAddress, askHasCep, askCep, confirmCepAddress, askStreetManual,
  askProducts, reviewProducts, askComments, shareLink,
  mainMenu, priceListMenu, priceListAddResult,
  pdfEditConfirmEntry, pdfEditMenu, pdfEditFieldInput, pdfEditConfirm,
  changeUsername, changeUsernameResult,
  logoMenu, logoViewResult,
}
```

O step é persistido em memória (`_currentFlowStep` no Repository) e orienta todo o processamento da mensagem.

---

## 3. Como o Chat Toma Decisões

### 3.1 Motor de Decisão: State Machine + Switch-Case

A lógica vive em `ChatAssistantViewModel._sendText()`:

```dart
if (_step == ChatFlowStep.mainMenu) {
  await _handleMainMenu(clean);
} else if (_step == ChatFlowStep.askClient) {
  _pendingClientName = clean;
  _setStep(ChatFlowStep.askPhone);
  await _addBotMessage(_script?.askPhone ?? fallback);
} else if (_step == ChatFlowStep.askPhone) {
  if (!_isValidPhone(clean)) { /* erro */ }
  else { /* avança */ }
}
// ... e assim por diante
```

**Características:**
- **Determinístico:** respostas 100% previsíveis
- **Imperativo:** lógica procedural em camadas de `if/else if`
- **Acoplada:** ViewModel conhece detalhes de validação (telefone, CEP) e navegação de telas
- **Sem NLP:** não entende linguagem natural; compara strings literais (`'1'`, `'SIM'`, `'Não'`)

### 3.2 Fluxo de Delegação por UseCases

Para manter a Clean Architecture, os menus delegam para UseCases que retornam `ChatMenuResult`:

```dart
class ChatMenuResult {
  final String nextStep;      // Próximo ChatFlowStep.name
  final String? navigation;   // Navegação para View externa (ex: 'open_pdf_edit')
}
```

UseCases principais:
| UseCase | Responsabilidade |
|---------|------------------|
| `ResetChatToMenuUsecase` | Limpa sessão e envia mensagem do menu principal |
| `HandleMainMenuOptionUsecase` | Roteia `1..4` para os subfluxos |
| `CreateBudgetFromChatUsecase` | Cria rascunho no Firestore e atualiza endereço |
| `HandlePdfEditMenuOptionUsecase` | Valida e persiste campos do PDF |

### 3.3 Arquitetura em Camadas

```
Presenter (View + ViewModel)
    ↓
Domain (UseCases + Entities + Repository Interfaces)
    ↓
Data (RepositoryImpl + RemoteDataSource)
    ↓
Firestore
```

**Persistência:**
- Sessão de chat: `EMPRESAS/{uid}/USERS/{uid}/CHAT_SESSIONS/{sessionId}/MESSAGES/{msgId}`
- Script de mensagens: `EMPRESAS/{uid}/CONFIG/CHAT_SCRIPT/DEFAULT`
- Orçamentos: reuse do `BudgetRepository` existente

---

## 4. Padrões de Mensagens

### 4.1 Tipos Suportados (`ChatMessageType`)

| Tipo | Uso | Exemplo de Conteúdo |
|------|-----|---------------------|
| `text` | Mensagens puras | `"Qual o telefone do cliente?"` |
| `inlineButtons` | Múltipla escolha em bolha | `"Confirmar dados", "Editar nome"` |
| `action` | Botão único que dispara navegação | `label: "Selecionar produtos", action: "open_products"` |
| `productList` | Resumo de itens com ação de editar | Lista formatada com total |
| `contactPicker` | Botão para abrir agenda do celular | — |
| `image` | Exibição de logo/imagem | Base64 ou URL |

### 4.2 Convenções de Conteúdo

- **Menu Principal:**  
  `O que eu posso fazer por você?\n\n1. Criar orçamentos\n2. Lista de preço\n3. Editar PDF\n4. Trocar nome de usuário`

- **Escape Global:** digitar `0` em qualquer fluxo volta ao `mainMenu`

- **Confirmação de Dados:** botões inline `[Confirmar dados, Editar nome, Editar telefone]`

---

## 5. É Inteligente ou é um Bot Simples?

**Resposta: é um bot simples (rule-based).**

Vantagens atuais:
- ✅ Rápido (zero latência de rede para IA)
- ✅ Gratuito (sem custo de tokens)
- ✅ Determinístico (fácil testar e reproduzir bugs)
- ✅ Funciona offline (mensagens ficam em memória)

Limitações:
- ❌ O usuário **deve** usar os números exatos dos menus
- ❌ Não entende variações de linguagem natural (`"quero fazer um orçamento"` não funciona)
- ❌ Não consegue fazer buscas complexas (`"mostre orçamentos pendentes de ontem"`)
- ❌ Cada novo fluxo exige novo `if/else` e novo `enum` — não escala bem

---

## 6. Roadmap: Adicionar LLM (Proposta)

### 6.1 O que muda

A proposta é manter o **bot atual como fallback** e adicionar uma **camada de interpretação via LLM** para:

1. **Compreensão de intenção:** o usuário digita `"quero criar um orçamento pro João"` e a LLM entende que deve iniciar o fluxo `askClient` com `_pendingClientName = "João"`.
2. **Function Calling (Tool Use):** a LLM pode chamar funções do app para buscar dados no Firestore sem que o usuário precise navegar por menus.
3. **Respostas amigáveis:** a LLM reformula mensagens de erro ou confirmação de forma mais natural.

### 6.2 Arquitetura Híbrida Proposta

```
┌─────────────────────────────────────────────────────────────┐
│                       USUÁRIO                                │
│  "Busque orçamentos pendentes do cliente João da semana"    │
└──────────────────────┬──────────────────────────────────────┘
                       │
           ┌───────────▼───────────┐
           │   Chat Input (Flutter) │
           └───────────┬───────────┘
                       │
         ┌─────────────▼─────────────┐
         │  Intent Router            │
         │  (Híbrido: Regex/LLM)     │
         └─────────────┬─────────────┘
                       │
       ┌───────────────┼───────────────┐
       │               │               │
   Match direto    Function Call    Fluxo Conversacional
   (menus 1-4)     (busca dados)   (criar/editar orçamento)
       │               │               │
       ▼               ▼               ▼
  ViewModel        Firestore     ViewModel + LLM
  original          Query        (acompanha passo a passo)
```

### 6.3 Function Calling — Exemplo Real

Cenário: usuário digita `"Mostre os orçamentos ainda não aprovados do cliente Silva"`

#### Tool Definition (enviada para a LLM)

```dart
final buscarOrcamentosTool = FunctionDeclaration(
  'buscarOrcamentos',
  'Busca orçamentos no Firestore filtrando por status, cliente e período.',
  parameters: {
    'status': Schema.string(
      description: "Status do orçamento. Valores: 'PENDENTE', 'APROVADO', 'REJEITADO'",
      nullable: true,
    ),
    'clienteNome': Schema.string(
      description: "Nome (ou parte) do cliente. Ex: 'Silva'",
      nullable: true,
    ),
    'dataInicio': Schema.string(
      description: "Data ISO8601 de início do filtro",
      nullable: true,
    ),
    'dataFim': Schema.string(
      description: "Data ISO8601 de fim do filtro",
      nullable: true,
    ),
  },
);
```

#### Interação com Gemini (Firebase AI Logic)

```dart
// 1. Configura o modelo com as ferramentas disponíveis
final model = FirebaseAI.googleAI().generativeModel(
  model: 'gemini-2.0-flash',
  tools: [Tool.functionDeclarations([buscarOrcamentosTool])],
);

// 2. Envia a mensagem do usuário
final response = await model.generateContent([
  Content.text('Mostre os orçamentos ainda não aprovados do cliente Silva'),
]);

// 3. Verifica se a LLM pediu uma função
if (response.functionCalls.isNotEmpty) {
  final call = response.functionCalls.first;
  final args = call.args;

  // 4. O APP executa a query no Firestore (não a LLM!)
  final query = FirebaseFirestore.instance
      .collectionGroup('ORCAMENTOS') // ou collection('orcamentos')
      .where('status', isEqualTo: args['status'] ?? 'PENDENTE')
      .orderBy('data', descending: true)
      .limit(20);

  final docs = await query.get();

  // 5. Devolve os dados para a LLM formatar a resposta final
  final functionResult = Content.functionResponse(
    call.name,
    {'orcamentos': docs.docs.map((d) => d.data()).toList()},
  );

  final finalResponse = await model.generateContent([
    Content.text('Mostre os orçamentos ainda não aprovados do cliente Silva'),
    Content.model([response.candidates.first.content]),
    functionResult,
  ]);

  // 6. Exibe a resposta amigável no chat
  await _addBotMessage(finalResponse.text ?? 'Nenhum resultado.');
}
```

### 6.4 Outras Ferramentas (Tools) que o App pode expor

| Nome da Função | Parâmetros | Retorno | Quando a LLM chama |
|----------------|-----------|---------|-------------------|
| `buscarOrcamentos` | `status`, `clienteNome`, `dataInicio`, `dataFim` | Lista de orçamentos | Usuário pede para listar/consultar |
| `criarOrcamento` | `clienteNome`, `telefone` | `orcamentoId` | Usuário quer iniciar um novo |
| `adicionarProdutoAoOrcamento` | `orcamentoId`, `produtoId`, `quantidade` | `bool success` | Durante fluxo de criação |
| `atualizarPdfEmpresa` | `campo` (nome, telefone, cnpj...), `valor` | `bool success` | Editar dados do PDF |
| `navegarParaTela` | `rota` (`budget_list`, `product_list`...) | — | Quando precisa abir uma tela específica |
| `alterarNomeUsuario` | `novoNome` | `bool success` | Trocar nome do usuário logado |

> **Regra de Ouro:** A LLM **nunca** acessa o Firestore diretamente. Ela só decide os parâmetros. O app executa a query e devolve os dados. Isso mantém a segurança e o custo baixo.

---

## 7. Custos com Firebase AI Logic

### 7.1 Preço de Referência (Gemini Flash)

| Modelo | Entrada (texto) | Saída (texto) |
|--------|----------------|---------------|
| Gemini 2.0 Flash | ~US$ 0.10 / 1M tokens | ~US$ 0.40 / 1M tokens |
| Gemini 2.5 Flash | similar | similar |

**Contexto de uso:**
- Cada requisição de Function Calling consome ~500–1.500 tokens (system prompt + tools definitions + mensagem do usuário + resposta).
- 1.000 consultas/mês ≈ **US$ 0.10 a US$ 0.50** (desprezível).

### 7.2 O que torna barato

- **Tokens mínimos:** você envia apenas a mensagem do usuário + definições das funções. Não envia o banco de dados.
- **Query pesada é local:** o Firestore executa o `where(...).get()`. A LLM só recebe o resultado ja filtrado (poucas linhas).
- **Sem backend extra:** Firebase AI Logic já gerencia a API key e rate limits.

### 7.3 Alternativas de Custo Zero

- Manter o **modo "Bot Simples"** como default e só acionar a LLM quando a mensagem não casar com nenhum padrão conhecido.
- Cachear system prompts e tool definitions em memória (só alteram em runtime).

---

## 8. Implementação Híbrida Sugerida (Passo a Passo)

### Fase 1: Detector de Intenção (sem custo)

Adicionar um `IntentClassifier` local antes do ViewModel:

```dart
enum UserIntent {
  createBudget,      // "criar orçamento", "novo orçamento"
  searchBudgets,     // "buscar", "mostrar", "quais"
  editPdf,           // "editar pdf", "mudar nome da empresa"
  priceList,         // "lista de preço", "produtos"
  changeUsername,    // "trocar nome", "alterar usuário"
  navigate,          // "abrir tela de..."
  unknown,           // não reconhecido → cair na LLM
}
```

Implementação: use regex simples ou um modelo de classificação local (sem custo). Se for `unknown`, encaminha para a LLM.

### Fase 2: Function Calling para Consultas

Implementar `buscarOrcamentosTool` e outras ferramentas de **leitura** primeiro (menor risco).

### Fase 3: Companion LLM no Fluxo de Orçamento

Manter o state machine existente, mas deixar a LLM:
- Confirmar dados extraídos (`"Entendi: cliente é João, telefone (11) 99999-9999. Confirma?"`)
- Reformular erros (`"Ops, o CEP 00000-000 não existe. Pode me passar a rua e cidade?"`)
- Sugerir produtos com base em histórico (se houver dados)

### Fase 4: Modo "Full LLM" (futuro)

Substituir o state machine por um agente que mantém o estado em memória (ou Firestore) e toda decisão passa pela LLM. Requer mais testes de segurança e custos.

---

## 9. Decisões de Design Importantes

| Decisão | Justificativa |
|---------|---------------|
| **Não restaurar conversa** (`initializeChat` sempre zera) | Simplifica o modelo mental: cada abertura é uma sessão nova |
| **Mensagens em memória + Firestore** | Chat funciona offline; Firebase sincroniza em background com falha silenciosa |
| **Repository como `ChangeNotifier`** | Facilita binding direto com ViewModel; reutiliza o budget existente via `BudgetRepository` |
| **Scripts configuráveis no Firestore** | Permite white-label sem recompilar o app |
| **Long-press para editar** | UX de WhatsApp; evita fluxo de tela separado para correção |

---

## 10. Estrutura de Pastas do Módulo

```
lib/modules/chat_assistant/
├── chat_assistant_binds.dart              # DI (get_it)
├── chat_assistant_routes.dart             # Rotas do módulo
├── domain/
│   ├── entity/
│   │   ├── chat_message_entity.dart       # Mensagem pura
│   │   └── chat_script_entity.dart        # Textos configuráveis
│   ├── repository/
│   │   ├── chat_budget_repository.dart    # Contrato de sessão + rascunho
│   │   └── chat_script_repository.dart    # Contrato de script
│   └── usecase/                           # ~20 usecases (menus, PDF, etc.)
├── data/
│   ├── datasource/
│   │   ├── chat_budget_remote_datasource.dart   # Firestore: sessões/mensagens
│   │   └── chat_script_remote_datasource.dart   # Firestore: script de mensagens
│   └── repository/
│       ├── chat_budget_repository_impl.dart
│       └── chat_script_repository_impl.dart
└── presenter/
    ├── enum/
    │   └── chat_flow_step_enum.dart       # State machine steps
    ├── strings/
    │   └── chat_budget_pt_string.dart     # i18n PT/EN
    ├── chat_assistant/
    │   ├── chat_assistant_view.dart       # Tela (WhatsApp-like)
    │   ├── chat_assistant_view_model.dart # ViewModel (state machine)
    │   └── components/
    │       ├── chat_message_bubble.dart   # Renderização por tipo
    │       └── chat_input_bar.dart        # Input + formulário de endereço
```

---

## 11. Checklist: Queremos LLM?

| Pergunta | Resposta |
|----------|----------|
| É possível? | **Sim.** Function Calling é o padrão recomendado. |
| É caro? | **Não.** Se feito corretamente (app executa queries), custo é desprezível para pequena/média escala. |
| Precisa de backend? | **Não obrigatoriamente.** Firebase AI Logic + Flutter SDK consome Gemini direto. Para apps com muitos usuários, um Cloud Function é recomendado para proteger a API key. |
| Funciona offline? | **Parcial.** O bot simples funciona. Consultas LLM precisam de internet. |
| Compatível com o app hoje? | **Sim.** Arquitetura híbrida permite migrar gradualmente. |

---

## 12. Exemplo de Resposta da LLM fora do Escopo

Se o usuário pedir algo que **não está implementado** (ex: `"Altere o status do orçamento #129922928"`):

1. A LLM recebe a mensagem.
2. Não encontra `tool` compatível para "alterar status".
3. Responde com texto amigável:  
   *"Ainda não consigo alterar o status de um orçamento existente por aqui. Para isso, acesse a lista de orçamentos na tela inicial. Quer que eu te leve até lá?"`

Isso é controlado pela **ausência de tools** e pelo **system prompt** instruindo a LLM a ser honesta sobre limitações.

---

> **Autor:** Pi Coding Agent  
> **Gerado em:** Análise do codebase atual + recomendações de arquitetura LLM
