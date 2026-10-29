# Plano de Implementação — Chat Bot de Orçamentos (Assistente)

> **Escopo:** Nova aba "Assistente" no `MainTabView` que permite ao usuário criar um orçamento inteiro apenas conversando com um bot, com a conversa de perguntas/respostas armazenada no Firestore (editável a qualquer momento).
> 
> **Restrições:** Não alterar código que já funciona. Reutilizar telas e repositórios existentes (`BudgetRepository`, `ProductPriceRepository`, `BudgetShareLinkService`, `ViaCepService`, `BudgetListItemsView`, `ProductPriceListView`, `BudgetCreatorViewModel`, etc.). Seguir fielmente a arquitetura descrita em `ARQUITETURA.md`.

---

## 1. Visão Geral do Fluxo

```
┌─────────────────────────────────────────────────────────────────┐
│  ABA ASSISTENTE (chat estilo WhatsApp)                          │
│                                                                 │
│  [USUÁRIO digita qualquer coisa ou toca em iniciar]            │
│  → BOT: "Para quem você quer criar um orçamento?"              │
│                                                                 │
│  [Botão "Escolher contato"  ou  campo de texto]                │
│  → Usuário seleciona/digita nome do cliente                    │
│  → Cria CustomerInfo no Firebase via BudgetRepository           │
│                                                                 │
│  [BOT pergunta:] "Quer cadastrar o endereço do cliente?"       │
│  [Botões: SIM / NÃO]                                           │
│                                                                 │
│  SIM → "Informe o CEP:"                                        │
│       → Se CEP válido: preenche rua, bairro, cidade (ViaCEP)   │
│       → Se não tiver CEP: pede Rua, Número e Cidade manualmente│
│  NÃO → Pula para produtos                                      │
│                                                                 │
│  [BOT:] "Selecione os produtos do orçamento"                   │
│  [Botão "Abrir lista de produtos"]                             │
│  → Abre tela existente de seleção com modo "seleção múltipla"  │
│  → Botão "Finalizar seleção" retorna para o chat               │
│                                                                 │
│  [Chat mostra os produtos selecionados como mensagem]           │
│  → Cada mensagem de produtos tem botão "Editar"                │
│  → Toque abre a mesma tela de seleção para editar               │
│                                                                 │
│  [BOT:] "Orçamento gerado!"                                    │
│  [Botão "Compartilhar link"]                                   │
│  → Usa BudgetShareLinkService para gerar URL                   │
│  → share_plus para compartilhar nativamente                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Estrutura de Pastas do Novo Módulo

```
lib/modules/chat_budget/
├── chat_budget_binds.dart
├── chat_budget_routes.dart
├── domain/
│   ├── entity/
│   │   └── chat_message_entity.dart      # Mensagem do chat (bot ou usuário)
│   ├── entity/
│   │   └── chat_script_entity.dart       # Script do bot (perguntas/respostas)
│   ├── repository/
│   │   ├── chat_budget_repository.dart   # Contrato: criar/listar msgs + gerir orçamento
│   │   └── chat_script_repository.dart   # Contrato: buscar script do Firestore
│   └── usecase/
│       ├── create_budget_from_chat_usecase.dart
│       └── fetch_chat_script_usecase.dart
├── data/
│   ├── datasource/
│   │   ├── chat_budget_remote_datasource.dart   # Firestore: mensagens
│   │   ├── chat_script_remote_datasource.dart   # Firestore: script/perguntas
│   │   └── chat_budget_local_datasource.dart    # SharedPreferences: rascunho local
│   ├── model/
│   │   ├── request/
│   │   │   └── chat_message_request.dart
│   │   │   └── chat_script_request.dart
│   │   └── response/
│   │       └── chat_script_response.dart
│   └── repository/
│       ├── chat_budget_repository_impl.dart
│       └── chat_script_repository_impl.dart
└── presenter/
    ├── chat_assistant/
    │   ├── chat_assistant_view.dart
    │   ├── chat_assistant_view_model.dart
    │   └── components/
    │       ├── chat_message_bubble.dart
    │       ├── chat_action_button.dart
    │       ├── chat_contact_selector.dart
    │       ├── chat_product_summary.dart
    │       └── chat_input_bar.dart
    └── contact_picker_bottom_sheet/
        └── contact_picker_bottom_sheet.dart
```

---

## 3. Modelagem Firestore (Sem alterar coleções existentes)

### 3.1 Coleção do Script do Bot (nova)

```
EMPRESAS/{uidEmpresa}/CONFIG/CHAT_SCRIPT
```

Documento `DEFAULT` (ou por empresa):
```json
{
  "welcomeMessage": "Olá! Sou seu assistente de orçamentos. Para quem você quer criar um orçamento?",
  "askClientName": "Qual o nome do cliente?",
  "askAddress": "Quer cadastrar o endereço do cliente?",
  "askCep": "Qual o CEP?",
  "askStreetFallback": "Informe a rua, número e cidade:",
  "askProducts": "Selecione os produtos do orçamento",
  "finalMessage": "Orçamento gerado com sucesso!",
  "shareLabel": "Compartilhar link do orçamento",
  "updatedAt": "2025-..."
}
```

> **Regra:** O usuário/admin pode editar esse documento direto no Firestore e o app reflete na próxima conversa.

### 3.2 Coleção de Histórico de Conversas (nova)

```
EMPRESAS/{uidEmpresa}/USERS/{uidUser}/CHAT_SESSIONS/{sessionId}/MESSAGES/{msgId}
```

Documento `session` (opcional, para auditoria):
```json
{
  "createdAt": "timestamp",
  "budgetId": "1729...",
  "status": "active | completed | abandoned"
}
```

Documento `message`:
```json
{
  "sender": "bot | user | system",
  "type": "text | action | product_list | contact_picker | inline_buttons",
  "content": "Texto da mensagem",
  "payload": {},
  "timestamp": "..."
}
```

---

## 4. Checklist de Implementação (Passo a Passo)

### FASE 1 — Infraestrutura e Configuração (sem UI)

#### 4.1.1 Criar `lib/modules/chat_budget/domain/entity/chat_message_entity.dart`

```dart
/// Entidade pura da mensagem no chat.
enum ChatSender { bot, user, system }
enum ChatMessageType { text, action, productList, contactPicker, inlineButtons }

class ChatMessageEntity {
  final String id;
  final ChatSender sender;
  final ChatMessageType type;
  final String content;
  final Map<String, dynamic>? payload; // dados extras (produtos selecionados, etc.)
  final DateTime timestamp;

  const ChatMessageEntity({
    required this.id,
    required this.sender,
    required this.type,
    required this.content,
    this.payload,
    required this.timestamp,
  });

  ChatMessageEntity copyWith({...}) => ...;
}
```

#### 4.1.2 Criar `lib/modules/chat_budget/domain/entity/chat_script_entity.dart`

```dart
/// Entidade do script configurável no Firestore.
class ChatScriptEntity {
  final String welcomeMessage;
  final String askClientName;
  final String askAddress;
  final String askCep;
  final String askStreetFallback;
  final String askProducts;
  final String finalMessage;
  final String shareLabel;

  const ChatScriptEntity({...});
}
```

#### 4.1.3 Criar `lib/modules/chat_budget/domain/repository/chat_script_repository.dart`

```dart
abstract class ChatScriptRepository extends ChangeNotifier {
  ChatScriptEntity? get currentScript;
  Future<Result<ChatScriptEntity>> fetchScript();
}
```

#### 4.1.4 Criar `lib/modules/chat_budget/data/datasource/chat_script_remote_datasource.dart`

```dart
/// Lê o documento `EMPRESAS/{uid}/CONFIG/CHAT_SCRIPT/DEFAULT`.
class ChatScriptRemoteDataSource {
  final FirebaseFirestore _firestore;
  ...
  Future<Map<String, dynamic>> getScript() async { ... }
}
```

#### 4.1.5 Criar `lib/modules/chat_budget/data/repository/chat_script_repository_impl.dart`

```dart
class ChatScriptRepositoryImpl extends ChatScriptRepository {
  final ChatScriptRemoteDataSource _remote;
  ChatScriptEntity? _cached;

  @override ChatScriptEntity? get currentScript => _cached;

  @override Future<Result<ChatScriptEntity>> fetchScript() async {
    try {
      final raw = await _remote.getScript();
      _cached = ChatScriptEntity(...); // mapear
      notifyListeners();
      return Result.ok(_cached!);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
```

#### 4.1.6 Criar `lib/modules/chat_budget/domain/usecase/fetch_chat_script_usecase.dart`

```dart
class FetchChatScriptUsecase {
  final ChatScriptRepository _repo;
  const FetchChatScriptUsecase(this._repo);

  Future<Result<ChatScriptEntity>> call() => _repo.fetchScript();
}
```

---

### FASE 2 — Repositório de Chat + Orquestração de Orçamentos

#### 4.2.1 Criar `lib/modules/chat_budget/domain/repository/chat_budget_repository.dart`

```dart
/// Contrato que une:
/// 1) CRUD de mensagens de sessão
/// 2) Criação/edição de orçamentos via BudgetRepository (injetado)
/// 3) Salvamento de itens de orçamento
abstract class ChatBudgetRepository extends ChangeNotifier {
  String? get currentSessionId;
  CustomerInfo? get draftBudget;
  List<ChatMessageEntity> get messages;

  /// Inicia uma nova sessão de chat e cria o orçamento vazio.
  Future<Result<CustomerInfo>> createDraftBudget(String clientName);

  /// Atualiza endereço no rascunho.
  Future<Result<void>> updateDraftAddress({
    String? street,
    String? city,
    String? neighborhood,
    String? zip,
  });

  /// Adiciona itens ao rascunho.
  Future<Result<void>> addItemsToDraft(List<ItemsBudget> items);

  /// Remove itens do rascunho.
  Future<Result<void>> removeItemsFromDraft(List<ItemsBudget> items);

  /// Salva uma mensagem na sessão ativa (localmente + remoto opcional).
  Future<Result<void>> sendMessage(ChatMessageEntity message);

  /// Marca sessão como completa e devolve o orçamento final.
  Future<Result<CustomerInfo>> finalizeDraft();

  /// Limpa sessão atual.
  void clearSession();
}
```

#### 4.2.2 Criar `lib/modules/chat_budget/data/datasource/chat_budget_remote_datasource.dart`

```dart
/// Grava mensagens em:
/// EMPRESAS/{uid}/USERS/{uid}/CHAT_SESSIONS/{sessionId}/MESSAGES/{msgId}
class ChatBudgetRemoteDataSource {
  final FirebaseFirestore _firestore;
  ...
  Future<void> saveMessage(String sessionId, Map<String, dynamic> data) async { ... }
  Future<List<Map<String, dynamic>>> fetchMessages(String sessionId) async { ... }
  Future<void> createSession(String sessionId, Map<String, dynamic> meta) async { ... }
}
```

#### 4.2.3 Criar `lib/modules/chat_budget/data/repository/chat_budget_repository_impl.dart`

```dart
class ChatBudgetRepositoryImpl extends ChatBudgetRepository {
  final ChatBudgetRemoteDataSource _chatRemote;
  final BudgetRepository _budgetRepo; // já existe no DI

  String? _sessionId;
  CustomerInfo? _draft;
  List<ChatMessageEntity> _messages = [];

  String _generateSessionId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Future<Result<CustomerInfo>> createDraftBudget(String clientName) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final formattedDate = DateFormat('dd/MM/yyyy').format(now);

    final budget = CustomerInfo(
      id: id,
      data: formattedDate,
      customerName: clientName,
      status: 'PENDENTE',
      totalValue: 0,
    );

    final saveResult = await _budgetRepo.saveBudget(budget);
    if (saveResult is Error<void>) return Result.error(saveResult.error);

    _draft = budget;
    _sessionId = _generateSessionId();
    await _chatRemote.createSession(_sessionId!, {'budgetId': id, 'createdAt': FieldValue.serverTimestamp()});
    notifyListeners();
    return Result.ok(budget);
  }

  @override Future<Result<void>> updateDraftAddress({...}) async { ... }

  @override Future<Result<void>> addItemsToDraft(List<ItemsBudget> items) async {
    if (_draft?.id == null) return Result.error(Exception('Sem rascunho'));
    for (final it in items) {
      await _budgetRepo.saveBudgetItem(_draft!.id!, it);
    }
    // opcional: recalcular total
    notifyListeners();
    return Result.ok(null);
  }

  @override Future<Result<void>> sendMessage(ChatMessageEntity msg) async {
    _messages.add(msg);
    if (_sessionId != null) {
      await _chatRemote.saveMessage(_sessionId!, {
        'sender': msg.sender.name,
        'type': msg.type.name,
        'content': msg.content,
        'payload': msg.payload,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    notifyListeners();
    return Result.ok(null);
  }

  @override Future<Result<CustomerInfo>> finalizeDraft() async { ... }
}
```

#### 4.2.4 Criar `lib/modules/chat_budget/domain/usecase/create_budget_from_chat_usecase.dart`

```dart
/// Orquestra a criação completa de um orçamento via chat.
class CreateBudgetFromChatUsecase {
  final ChatBudgetRepository _chatRepo;
  final ChatScriptRepository _scriptRepo;

  const CreateBudgetFromChatUsecase(this._chatRepo, this._scriptRepo);

  /// Passos do fluxo a serem chamados pelo ViewModel conforme interação do usuário.
}
```

---

### FASE 3 — UI do Chat (Apresentação)

#### 4.3.1 Criar `lib/modules/chat_budget/presenter/chat_assistant/components/chat_message_bubble.dart`

- Bolha estilo WhatsApp:
  - **Bot:** fundo cinza escuro, alinhado à esquerda, ícone de robô.
  - **Usuário:** fundo cyan/verde-água, alinhado à direita.
  - **Tipo `action`/`contactPicker`:** bolha com botões inline.
  - **Tipo `productList`:** bolha com lista resumida + botão "Editar".

#### 4.3.2 Criar `lib/modules/chat_budget/presenter/chat_assistant/components/chat_action_button.dart`

```dart
/// Botão estilizado para ações dentro da bolha do bot.
/// Ex: [Escolher Contato]  [Sim] [Não]  [Abrir Produtos]
class ChatActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  ...
}
```

#### 4.3.3 Criar `lib/modules/chat_budget/presenter/chat_assistant/components/chat_product_summary.dart`

```dart
/// Card interno da bolha de produtos, mostrando:
/// - Nome do produto
/// - Qtd × Preço = Total
/// - Botão "Editar seleção" que dispara callback para abrir ProductPriceListView
class ChatProductSummary extends StatelessWidget {
  final List<ItemsBudget> items;
  final VoidCallback onEdit;
  ...
}
```

#### 4.3.4 Criar `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart`

```dart
class ChatAssistantViewModel extends ChangeNotifier {
  final ChatBudgetRepository _chatRepo;
  final ChatScriptRepository _scriptRepo;
  final BudgetShareLinkService _shareService; // usar static method
  final ViaCepService _cepService;

  // Estado do fluxo
  ChatFlowStep _currentStep = ChatFlowStep.welcome;
  List<ChatMessageEntity> get messages => _chatRepo.messages;
  ChatScriptEntity? get script => _scriptRepo.currentScript;
  bool get isLoading => _loadingCommand.running;

  // Commands
  late final Command0<void> initializeChat;
  late final Command1<void, String> sendUserText;
  late final Command0<void> pickContact;
  late final Command0<void> createDraftFromContact;
  late final Command0<void> skipAddress;
  late final Command1<void, String> submitCep;
  late final Command1<void, StreetData> submitManualAddress;
  late final Command0<void> openProductSelection;
  late final Command1<void, List<ItemsBudget>> confirmProductSelection;
  late final Command0<void> shareBudgetLink;

  void _handleAnyInput() {
    // Qualquer input do usuário no estado inicial
    if (_currentStep == ChatFlowStep.welcome) {
      _currentStep = ChatFlowStep.askClient;
      _addBotMessage(script!.askClientName, type: ChatMessageType.contactPicker);
    }
  }

  Future<void> _pickContact() async {
    // Usa flutter_contact-picker existente
    final contact = await FlutterContactPicker.pickFullContact();
    final name = contact.name?.nickName ?? contact.name?.first ?? 'Cliente';
    await _createDraft(name);
  }

  Future<void> _createDraft(String name) async {
    final result = await _chatRepo.createDraftBudget(name);
    if (result is Ok<CustomerInfo>) {
      _currentStep = ChatFlowStep.askAddress;
      _addBotMessage(script!.askAddress, type: ChatMessageType.inlineButtons,
        payload: {'actions': ['SIM', 'NÃO']});
    }
  }

  Future<void> _submitCep(String cep) async {
    final addr = await _cepService.getAdress(cep);
    await _chatRepo.updateDraftAddress(
      zip: cep,
      street: addr.logradouro,
      city: addr.localidade,
      neighborhood: addr.bairro,
    );
    _currentStep = ChatFlowStep.askProducts;
    _addBotMessage(script!.askProducts, type: ChatMessageType.action);
  }

  Future<void> _confirmProducts(List<ItemsBudget> items) async {
    await _chatRepo.addItemsToDraft(items);
    _currentStep = ChatFlowStep.shareLink;
    // Adiciona mensagem de resumo com payload dos produtos
    _addBotMessage(script!.finalMessage, type: ChatMessageType.productList,
      payload: {'items': items.map((e) => e.toJson()).toList()});
  }

  Future<void> _shareLink() async {
    final budgetId = _chatRepo.draftBudget?.id;
    if (budgetId == null) return;
    final url = await BudgetShareLinkService.buildShareUrl(enderecoNumero: budgetId);
    if (url != null) {
      await Share.share(url, subject: 'Seu orçamento');
    }
  }

  void _addBotMessage(String text, {ChatMessageType type = ChatMessageType.text, Map<String, dynamic>? payload}) {
    final msg = ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: ChatSender.bot,
      type: type,
      content: text,
      payload: payload,
      timestamp: DateTime.now(),
    );
    _chatRepo.sendMessage(msg);
  }
}
```

#### 4.3.5 Criar enum `ChatFlowStep`

```dart
enum ChatFlowStep {
  welcome,       // aguardando qualquer input
  askClient,     // perguntando nome do cliente
  askAddress,    // pergunta se quer endereço
  askCep,        // perguntando CEP
  askStreetManual, // rua/número/cidade manual
  askProducts,   // selecionar produtos
  reviewProducts,// exibindo resumo dos produtos
  shareLink,     // orçamento pronto, compartilhar
}
```

#### 4.3.6 Criar `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view.dart`

```dart
class ChatAssistantView extends StatefulWidget {
  const ChatAssistantView({super.key});
  @override State<ChatAssistantView> createState() => _ChatAssistantView();
}

class _ChatAssistantView extends State<ChatAssistantView> {
  late final ChatAssistantViewModel _vm;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override void initState() {
    super.initState();
    _vm = getIt<ChatAssistantViewModel>();
    _vm.initializeChat.execute();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente')),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _vm.messages.length,
                  itemBuilder: (context, index) {
                    final msg = _vm.messages[index];
                    return ChatMessageBubble(
                      message: msg,
                      onAction: (action) => _handleAction(action, msg),
                    );
                  },
                ),
              ),
              _buildInputBar(),
            ],
          );
        },
      ),
    );
  }

  void _handleAction(String action, ChatMessageEntity msg) {
    switch (action) {
      case 'pick_contact':
        _vm.pickContact.execute();
        break;
      case 'skip_address':
        _vm.skipAddress.execute();
        break;
      case 'open_products':
        _openProductSelection();
        break;
      case 'share_link':
        _vm.shareBudgetLink.execute();
        break;
      case 'SIM':
        _currentStep = ChatFlowStep.askCep;
        _addBotMessage('Qual o CEP?');
        break;
      case 'NÃO':
        _vm.skipAddress.execute();
        break;
    }
  }

  Future<void> _openProductSelection() async {
    // Reutiliza ProductPriceListView em modo "seleção múltipla + finalizar"
    final selected = await Navigator.push<List<ItemsBudget>>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductPriceListView(
          item: _vm.draftBudget,
          fromMenu: false,
          selectionMode: true, // NOVO PARAM
        ),
      ),
    );
    if (selected != null && selected.isNotEmpty) {
      await _vm.confirmProductSelection.execute(selected);
    }
  }
}
```

**IMPORTANTE sobre reutilização de tela de produtos:**

A `ProductPriceListView` já possui `item` e `fromMenu`. Precisamos adicionar um novo parâmetro opcional `bool selectionMode = false` que:
1. Esconde FABs de delete/adicionar produto.
2. Mostra checkbox em todos os cards.
3. Adiciona `BottomAppBar` com botão "Finalizar seleção (X itens)".
4. Ao tocar "Finalizar", converte `ProductPriceModel` selecionados para `ItemsBudget` e retorna via `Navigator.pop(context, items)`.

> Essa alteração é **mínima e aditiva**, não alterando o comportamento existente quando `selectionMode == false`.

---

### FASE 4 — Integração com o App (Tab + DI + Rotas)

#### 4.4.1 Modificar `lib/modules/main_tab/presenter/main_tab_view_model.dart`

```dart
// ADICIONAR novo item na lista:
final List<TabItem> _tabItems = [
  TabItem(icon: Icons.support_agent, title: 'Assistente'), // ← NOVO (índice 0)
  TabItem(icon: Icons.dashboard, title: 'Dashboard'),        // ← índice 1
  TabItem(icon: Icons.inventory_outlined, title: 'Orçamentos'), // ← índice 2
  TabItem(icon: Icons.menu, title: 'Menu'),                  // ← índice 3
];
```

#### 4.4.2 Modificar `lib/modules/main_tab/presenter/main_tab_view.dart`

```dart
final List<Widget> children = [
  const ChatAssistantView(),    // ← NOVO
  const DashboardView(),
  const BudgetListView(),
  const MainConfigMenuView(),
];
```

#### 4.4.3 Criar `lib/modules/chat_budget/chat_budget_binds.dart`

```dart
void registerChatBudgetDependencies(GetIt sl) {
  // Datasources
  sl.registerLazySingleton<ChatScriptRemoteDataSource>(
    () => ChatScriptRemoteDataSource(),
  );
  sl.registerLazySingleton<ChatBudgetRemoteDataSource>(
    () => ChatBudgetRemoteDataSource(),
  );

  // Repositories
  sl.registerLazySingleton<ChatScriptRepository>(
    () => ChatScriptRepositoryImpl(sl<ChatScriptRemoteDataSource>()),
  );
  sl.registerLazySingleton<ChatBudgetRepository>(
    () => ChatBudgetRepositoryImpl(
      sl<ChatBudgetRemoteDataSource>(),
      sl<BudgetRepository>(),
    ),
  );

  // Usecases
  sl.registerLazySingleton<FetchChatScriptUsecase>(
    () => FetchChatScriptUsecase(sl<ChatScriptRepository>()),
  );
  sl.registerLazySingleton<CreateBudgetFromChatUsecase>(
    () => CreateBudgetFromChatUsecase(sl<ChatBudgetRepository>(), sl<ChatScriptRepository>()),
  );

  // ViewModels (factory)
  sl.registerFactory<ChatAssistantViewModel>(
    () => ChatAssistantViewModel(
      sl<ChatBudgetRepository>(),
      sl<ChatScriptRepository>(),
    ),
  );
}
```

#### 4.4.4 Modificar `lib/injection.dart`

```dart
import 'package:oflite/modules/chat_budget/chat_budget_binds.dart';

void setupDependencyInjection() {
  registerCoreDependencies(getIt);
  registerBudgetDependencies(getIt);
  registerReceiptDependencies(getIt);
  registerPaymentDependencies(getIt);
  registerProductDependencies(getIt);
  registerCommentDependencies(getIt);
  registerPdfDependencies(getIt);
  registerLoginDependencies(getIt);
  registerChatBudgetDependencies(getIt); // ← NOVO
}
```

---

### FASE 5 — Adaptações Mínimas em Código Existente

#### 4.5.1 `ProductPriceListView` — Adicionar modo seleção

**Arquivo:** `lib/modules/product/product_price_list/presenter/product_price_list_view.dart`

**Alterações:**
- Adicionar parâmetro `final bool selectionMode;` no construtor.
- Em `ProductPriceListViewModel`, adicionar:
  - `List<ProductPriceModel> selectedItems = [];`
  - `void toggleSelection(ProductPriceModel product)`
  - `void finalizeSelection(BuildContext context)` → `Navigator.pop(context, selectedItems.map(...).toList())`
- Na `View`, quando `selectionMode == true`:
  - Esconder FABs de delete e adicionar.
  - Mostrar `BottomAppBar` com botão "Finalizar seleção ({count})".
  - Checkbox nos cards em vez de navegação para edição.

**Compromisso:** tudo protegido por `if (selectionMode)`, zero impacto no fluxo atual.

#### 4.5.2 `BudgetShareLinkService` — Já existe

Nenhuma alteração necessária. O ViewModel chama:
```dart
final url = await BudgetShareLinkService.buildShareUrl(
  enderecoNumero: budget.id!,
);
```

#### 4.5.3 Dependência `share_plus`

Adicionar no `pubspec.yaml`:
```yaml
dependencies:
  share_plus: ^10.0.0  # ou versão compatível com o projeto
```

> Verificar conflitos de versão com pacotes existentes (`firebase`, etc.).

---

### FASE 6 — Mensagens Configuráveis no Firestore

#### 4.6.1 Script Padrão (Fallback)

Se o documento `CHAT_SCRIPT/DEFAULT` não existir, o `ChatScriptRepositoryImpl` retorna um fallback hardcoded (evita crash se admin não configurar):

```dart
const _fallback = ChatScriptEntity(
  welcomeMessage: 'Olá! Sou seu assistente de orçamentos.',
  askClientName: 'Para quem você quer criar um orçamento?',
  askAddress: 'Quer cadastrar o endereço do cliente?',
  askCep: 'Qual o CEP?',
  askStreetFallback: 'Informe a rua, número e cidade:',
  askProducts: 'Selecione os produtos do orçamento:',
  finalMessage: 'Orçamento gerado com sucesso!',
  shareLabel: 'Compartilhar link',
);
```

#### 4.6.2 Painel Admin (fora do app)

Documento editável diretamente no console Firebase ou via Cloud Function futura. O app lê em tempo real (ou no `initState` da tela) — não precisa de listener contínuo, apenas fetch no início da conversa.

---

## 5. Arquivos a Criar / Modificar — Resumo

### Criar (novos)

| # | Arquivo | Tipo |
|---|---------|------|
| 1 | `modules/chat_budget/chat_budget_binds.dart` | DI |
| 2 | `modules/chat_budget/domain/entity/chat_message_entity.dart` | Domain |
| 3 | `modules/chat_budget/domain/entity/chat_script_entity.dart` | Domain |
| 4 | `modules/chat_budget/domain/repository/chat_budget_repository.dart` | Domain |
| 5 | `modules/chat_budget/domain/repository/chat_script_repository.dart` | Domain |
| 6 | `modules/chat_budget/domain/usecase/create_budget_from_chat_usecase.dart` | Domain |
| 7 | `modules/chat_budget/domain/usecase/fetch_chat_script_usecase.dart` | Domain |
| 8 | `modules/chat_budget/data/datasource/chat_budget_remote_datasource.dart` | Data |
| 9 | `modules/chat_budget/data/datasource/chat_script_remote_datasource.dart` | Data |
| 10 | `modules/chat_budget/data/repository/chat_budget_repository_impl.dart` | Data |
| 11 | `modules/chat_budget/data/repository/chat_script_repository_impl.dart` | Data |
| 12 | `modules/chat_budget/presenter/chat_assistant/chat_assistant_view.dart` | Presenter |
| 13 | `modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart` | Presenter |
| 14 | `modules/chat_budget/presenter/chat_assistant/components/chat_message_bubble.dart` | Presenter |
| 15 | `modules/chat_budget/presenter/chat_assistant/components/chat_action_button.dart` | Presenter |
| 16 | `modules/chat_budget/presenter/chat_assistant/components/chat_product_summary.dart` | Presenter |
| 17 | `modules/chat_budget/presenter/chat_assistant/components/chat_input_bar.dart` | Presenter |

### Modificar (existentes, mudanças mínimas)

| # | Arquivo | Mudança |
|---|---------|---------|
| 1 | `lib/injection.dart` | Registrar `registerChatBudgetDependencies` |
| 2 | `modules/main_tab/presenter/main_tab_view_model.dart` | Adicionar tab "Assistente" no início |
| 3 | `modules/main_tab/presenter/main_tab_view.dart` | Incluir `ChatAssistantView` no children |
| 4 | `modules/product/product_price_list/presenter/product_price_list_view.dart` | Adicionar `selectionMode` + BottomAppBar finalizar |
| 5 | `modules/product/product_price_list/presenter/product_price_list_view_model.dart` | Lógica de seleção múltipla + retorno |
| 6 | `pubspec.yaml` | Adicionar `share_plus` |

---

## 6. Regras de Ouro Aplicadas

| Regra | Aplicação |
|-------|-----------|
| **View nunca acessa Datasource** | `ChatAssistantView` → `ChatAssistantViewModel` → `ChatBudgetRepositoryImpl` → `ChatBudgetRemoteDataSource` |
| **Datasource nunca retorna Entity** | `ChatBudgetRemoteDataSource` retorna `Map<String, dynamic>`. Conversão no `RepositoryImpl`. |
| **Usecase não faz I/O** | `CreateBudgetFromChatUsecase` orquestra repositories, não chama Firestore. |
| **Repositories podem ser reativos** | `ChatBudgetRepository` e `ChatScriptRepository` extendem `ChangeNotifier`. |
| **ViewModel cuida de apresentação** | Lógica de bolhas, scroll, loading fica no `ChatAssistantViewModel`. |
| **Models isolados** | `ChatMessageRequest`/`ChatScriptResponse` não vazam para a View. |

---

## 7. Testes de Aceitação (Critérios)

- [ ] Ao abrir o app, a primeira aba é "Assistente" com ícone de robô.
- [ ] Tocar em qualquer coisa ou enviar mensagem faz o bot perguntar: "Para quem você quer criar um orçamento?"
- [ ] Aparece botão "Escolher contato" que abre picker nativo.
- [ ] Digitar nome manualmente e enviar cria o orçamento no Firebase.
- [ ] Bot pergunta se quer cadastrar endereço (botões SIM/NÃO).
- [ ] SIM → pergunta CEP. CEP válido preenche rua, bairro, cidade automaticamente.
- [ ] SIM sem CEP → pergunta rua, número e cidade manualmente.
- [ ] NÃO → pula direto para produtos.
- [ ] Bot diz "Selecione os produtos" com botão que abre lista de preço.
- [ ] Na lista de preço, modo seleção permite marcar múltiplos produtos + botão "Finalizar".
- [ ] Produtos selecionados aparecem no chat como mensagem resumo, com botão "Editar".
- [ ] Tocar em "Editar" abre a mesma lista de preço para alterar seleção.
- [ ] Após produtos, bot gera link e exibe botão "Compartilhar".
- [ ] Compartilhar dispara `share_plus` com a URL do orçamento.
- [ ] As mensagens do bot vêm do Firestore; alterar o documento muda o texto sem rebuild do app.
- [ ] Nenhuma tela ou funcionalidade existente quebrou.
