# 📁 Estrutura do Projeto — OFLite (Budget Flutter)

> **Arquitetura**: MVVM + Clean Architecture (simplificada)
> **Gerenciamento de Estado**: `ChangeNotifier` (Provider pattern) + `get_it` (Injeção de Dependência)
> **Roteamento**: `MaterialPageRoute` + Map de rotas estáticas

---

## 0. Ponytail — Regra de Ouro do Projeto

Este projeto segue o modo **ponytail full**: *o menor código completo que resolve o problema*.

- **Não** adicionamos abstração, wrapper, conversão de tipo ou configuração que ninguém pediu.
- **Não** criamos datasource em core que é puramente local (ex: `display_alert`, `loading_event`).
- **Criamos** datasource em core que acessa **fonte externa** (SDK de terceiros, Firebase, API REST).
- O shortest working diff vence. Deletar > adicionar.

Para detalhes completos: <https://github.com/DietrichGebert/ponytail/blob/main/skills/ponytail/SKILL.md>

---

## 1. Árvore de Diretórios (resumida — apenas `lib/`)

```
lib/
├── main.dart                          # Entrypoint mobile
├── main_web.dart                      # Entrypoint web
├── app_routes.dart                    # Agrupa todas as rotas dos módulos
├── injection.dart                     # Registro global do get_it
├── firebase_options.dart              # Config Firebase
│
├── modules/                           # 🔷 Cada pasta = um módulo de feature
│   ├── budget/                        # Orçamentos
│   │   ├── budget_binds.dart
│   │   ├── budget_routes.dart
│   │   ├── data/
│   │   │   ├── datasource/
│   │   │   │   └── budget_remote_datasource.dart
│   │   │   └── repository/
│   │   │       └── budget_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── repository/
│   │   │   │   └── budget_repository.dart
│   │   │   └── usecase/              # (quando necessário)
│   │   └── presenter/
│   │       ├── budget_list/
│   │       ├── budget_creator/
│   │       └── ...
│   │
│   ├── core/                          # 🔷 Serviços transversais (sem UI)
│   │   ├── ads/                       # Google Mobile Ads (tem datasource — SDK externo)
│   │   │   ├── ads_binds.dart
│   │   │   ├── domain/repository/ads_repository.dart
│   │   │   └── data/
│   │   │       ├── datasource/ads_remote_datasource.dart
│   │   │       └── repository/ads_repository_impl.dart
│   │   ├── convert_coin/              # Formatação local (sem datasource)
│   │   ├── display_alert/             # Snackbar/Alert local (sem datasource)
│   │   ├── loading_event/             # Loading local (sem datasource)
│   │   ├── in_app_purchase/           # Loja Google/Apple (tem datasource — SDK externo)
│   │   ├── notification/              # FCM + local notifications (tem datasource — SDK externo)
│   │   ├── cep/                       # Consulta externa (tem datasource)
│   │   ├── share_link/                # Compartilhamento (tem datasource)
│   │   └── ...
│   │
│   ├── dashboard/                     # Dashboard com gráficos
│   │   ├── dashboard_binds.dart
│   │   ├── dashboard_routes.dart      # ← obrigatório: tem view
│   │   └── presenter/
│   │       ├── dashboard_view.dart
│   │       └── dashboard_view_model.dart
│   │
│   ├── login/
│   ├── payment/
│   ├── pdf/
│   ├── product/
│   ├── receipt/
│   ├── subscription/
│   ├── chat_budget/
│   ├── main_config_menu/              # Menu de configurações
│   │   ├── main_config_menu_binds.dart
│   │   ├── main_config_menu_routes.dart   # ← obrigatório: tem view
│   │   └── presenter/
│   │       ├── main_config_menu_view.dart
│   │       └── main_config_menu_view_model.dart
│   ├── main_tab/
│   ├── terms_conditions/
│   ├── web_budget/
│   └── ...
│
└── shared/
    ├── common/
    ├── design_pattern/
    └── models/
```

---

## 2. Convenções de Nomenclatura

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| View (página) | `{feature}_view.dart` | `budget_list_view.dart` |
| ViewModel | `{feature}_view_model.dart` | `budget_list_view_model.dart` |
| Componente | `{feature}_{nome}.dart` | `budget_list_card.dart` |
| Modal | `{feature}_{acao}_bottom_modal_widget.dart` | `budget_list_delete_bottom_modal_widget.dart` |
| DataSource | `{feature}_remote_datasource.dart` | `budget_remote_datasource.dart` |
| Repository (impl) | `{feature}_repository_impl.dart` | `budget_repository_impl.dart` |
| Repository (interface) | `{feature}_repository.dart` | `budget_repository.dart` |
| UseCase | `{acao}_{feature}_usecase.dart` | `create_budget_from_chat_usecase.dart` |
| Binds | `{module}_binds.dart` | `budget_binds.dart` |
| Routes | `{module}_routes.dart` | `budget_routes.dart` |

---

## 3. O DataSource — Papel, Regras e Exemplo Real

### 3.1 O que é o DataSource?

O **DataSource** é a classe que **fala diretamente com o mundo externo**:</br>
`FirebaseFirestore`, `FirebaseAuth`, `http` (APIs REST), `SharedPreferences`, `FirebaseStorage`, SDKs de terceiros (Google Mobile Ads, FlutterInappPurchase, etc.), sensores do celular.

Ele **não conhece** models de negócio, entidades ou regras do domínio. Sua única responsabilidade é **trocar dados brutos** (`Map<String, dynamic>`, `String`, `Uint8List`, etc.) com a fonte externa.

### 3.2 O que o DataSource NÃO faz?

| ❌ NÃO faz | ✅ Quem faz |
|-----------|------------|
| Converter JSON → Model/Entity | `RepositoryImpl` |
| Validar regras de negócio | `ViewModel` ou `UseCase` |
| Acessar `BuildContext` ou widgets | `View` (Widget) |
| Conter lógica de apresentação (UI) | `View` |
| Conter `ChangeNotifier` | `ViewModel` |

### 3.3 Regras de Ouro do DataSource

1. **Retorna/tipifica apenas tipos primitivos ou `Map<String, dynamic>`** — nunca models do domínio.
2. **Não lança exceções customizadas de negócio** — pode lançar exceções técnicas (FirebaseException, SocketException, etc.) que serão tratadas pelo Repository ou UseCase.
3. **É injetado no RepositoryImpl** — a ViewModel nunca vê o DataSource.
4. **Permite mock no construtor** — aceitar a instância externa (ex: `FirebaseFirestore? firestore`) facilita testes unitários.

### 3.4 Quando um módulo `core/` PRECISA de DataSource?

| Módulo | Fonte externa? | DataSource? |
|--------|---------------|------------|
| `core/cep` | Sim (API ViaCep) | ✅ Sim |
| `core/share_link` | Sim (Firebase Dynamic Links / SDK) | ✅ Sim |
| `core/ads` | Sim (Google Mobile Ads SDK) | ✅ Sim |
| `core/in_app_purchase` | Sim (Google Play / App Store SDK) | ✅ Sim |
| `core/notification` | Sim (FCM + Firestore) | ✅ Sim |
| `core/convert_coin` | Não (pura formatação `intl`) | ❌ Não |
| `core/display_alert` | Não (snackbar local) | ❌ Não |
| `core/loading_event` | Não (dialog local) | ❌ Não |

> **Regra**: se o módulo `core/` acessa qualquer SDK externo, Firebase, HTTP ou storage, ele **deve** ter `data/datasource/`.

### 3.5 Exemplo Real — `BudgetRemoteDataSource`

**Arquivo**: `lib/modules/budget/data/datasource/budget_remote_datasource.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as UID;

/// Fonte de dados remota para orçamentos (Firebase Firestore).
///
/// Não conhece `Entity`; trabalha apenas com `Map<String, dynamic>`.
/// A conversão para models/entities acontece no [BudgetRepositoryImpl].
class BudgetRemoteDataSource {
  final FirebaseFirestore _firestore;

  BudgetRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _budgetsCollection =>
      _firestore.collection('EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS');

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final snapshot =
        await _budgetsCollection.orderBy('ID', descending: true).get();
    return snapshot.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getBudgetById(String id) async {
    final doc = await _budgetsCollection.doc(id).get();
    final data = doc.data();
    if (data == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveBudget(Map<String, dynamic> data) async {
    final id = data['ID'] as String?;
    if (id == null) throw Exception('ID is required');
    await _budgetsCollection.doc(id).set(data);
  }

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    await _budgetsCollection.doc(id).update(data);
  }

  Future<void> deleteBudget(String id) async {
    await _budgetsCollection.doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> getBudgetItems(String budgetId) async {
    final snapshot = await _budgetsCollection
        .doc(budgetId)
        .collection('ITENS')
        .orderBy('CATEGORIA', descending: false)
        .get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> saveBudgetItem(
      String budgetId, String itemId, Map<String, dynamic> data) async {
    await _budgetsCollection
        .doc(budgetId)
        .collection('ITENS')
        .doc(itemId)
        .set(data);
  }

  Future<void> deleteBudgetItem(String budgetId, String itemId) async {
    await _budgetsCollection
        .doc(budgetId)
        .collection('ITENS')
        .doc(itemId)
        .delete();
  }
}
```

> **Observe**: o DataSource expõe métodos como `getBudgets()`, `saveBudget()`, `deleteBudgetItem()`, mas trabalha **exclusivamente** com `Map<String, dynamic>` e tipos nativos (`String`, `void`).

---

## 4. Como Funciona o Gerenciamento de Estado

### 4.1 Stack tecnológica
- **`get_it`**: Injeção de dependências (Service Locator)
- **`ChangeNotifier`**: Notificação de mudanças de estado (classe nativa do Flutter)
- **Padrão Observer**: A View escuta o ViewModel via `addListener` / `notifyListeners`

### 4.2 Ciclo de vida

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  ViewModel  │────▶│  notify()   │────▶│    View     │
│  (estado)   │     │  listeners  │     │  (rebuild)  │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                                      │
       └────────── Ação do usuário ───────────┘
```

### 4.3 Regras do `injection.dart`

| Tipo | Registro | Motivo |
|------|----------|--------|
| DataSources | `registerLazySingleton` | Compartilhado, mantém cache de conexão |
| Repositories | `registerLazySingleton` | Mantém cache em memória |
| ViewModels | `registerFactory` | Sempre nova instância ao abrir a tela |

---

## 5. Como Criar um Módulo (passo a passo)

> Exemplo criando um módulo fictício chamado `invoice` (notas fiscais).

### 5.1 Criar a árvore de pastas

```bash
mkdir -p lib/modules/invoice/data/datasource
mkdir -p lib/modules/invoice/data/repository
mkdir -p lib/modules/invoice/domain/repository
mkdir -p lib/modules/invoice/presenter/invoice_list/components
mkdir -p lib/modules/invoice/presenter/invoice_creator/components
```

### 5.2 Interface do Repository (camada Domain)

**Arquivo**: `lib/modules/invoice/domain/repository/invoice_repository.dart`

```dart
abstract class InvoiceRepository {
  Future<List<Invoice>> fetchInvoices(String userId);
  Future<void> createInvoice(Invoice invoice);
  Future<void> deleteInvoice(String id);
}
```

### 5.3 DataSource (camada Data — fonte remota)

**Arquivo**: `lib/modules/invoice/data/datasource/invoice_remote_datasource.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getInvoices(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<void> addInvoice(Map<String, dynamic> data) async {
    await _firestore.collection('invoices').add(data);
  }

  Future<void> removeInvoice(String id) async {
    await _firestore.collection('invoices').doc(id).delete();
  }
}
```

### 5.4 Repository Implementation (camada Data)

**Arquivo**: `lib/modules/invoice/data/repository/invoice_repository_impl.dart`

```dart
import 'package:oflite/modules/invoice/data/datasource/invoice_remote_datasource.dart';
import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/shared/models/invoice.dart'; // modelo

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource _dataSource;

  InvoiceRepositoryImpl(this._dataSource);

  @override
  Future<List<Invoice>> fetchInvoices(String userId) async {
    final raw = await _dataSource.getInvoices(userId);
    return raw.map((json) => Invoice.fromJson(json)).toList();
  }

  @override
  Future<void> createInvoice(Invoice invoice) async {
    await _dataSource.addInvoice(invoice.toJson());
  }

  @override
  Future<void> deleteInvoice(String id) async {
    await _dataSource.removeInvoice(id);
  }
}
```

### 5.5 ViewModel (camada Presenter)

**Arquivo**: `lib/modules/invoice/presenter/invoice_list/invoice_list_view_model.dart`

```dart
import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/shared/models/invoice.dart';

class InvoiceListViewModel extends ChangeNotifier {
  final InvoiceRepository _repository = getIt<InvoiceRepository>();

  List<Invoice> invoices = [];
  bool isLoading = false;
  String? errorMessage;

  InvoiceListViewModel() {
    loadInvoices(); // carrega ao instanciar (opcional)
  }

  Future<void> loadInvoices() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      invoices = await _repository.fetchInvoices('user_id_here');
    } catch (e) {
      errorMessage = 'Erro ao carregar notas fiscais';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    await _repository.deleteInvoice(id);
    invoices.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    // limpeza de listeners, controllers, etc.
    super.dispose();
  }
}
```

> **Importante**: ViewModels **sempre** extendem `ChangeNotifier`. Chamam `notifyListeners()` toda vez que o estado muda.

### 5.6 View (camada Presenter — tela)

**Arquivo**: `lib/modules/invoice/presenter/invoice_list/invoice_list_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'invoice_list_view_model.dart';

class InvoiceListView extends StatefulWidget {
  const InvoiceListView({super.key});

  @override
  State<InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<InvoiceListView> {
  final InvoiceListViewModel _viewModel = getIt<InvoiceListViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onModelChanged);
    _viewModel.loadInvoices(); // garante carga inicial
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onModelChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notas Fiscais')),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _viewModel.errorMessage != null
              ? Center(child: Text(_viewModel.errorMessage!))
              : ListView.builder(
                  itemCount: _viewModel.invoices.length,
                  itemBuilder: (_, index) {
                    final invoice = _viewModel.invoices[index];
                    return ListTile(
                      title: Text(invoice.number),
                      subtitle: Text('R\$ ${invoice.total.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _viewModel.delete(invoice.id),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // navegar para InvoiceCreatorView
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

> **Regra**: A View **nunca** acessa o Repository diretamente. Só conversa com o ViewModel. A UI é reativa: o `addListener` chama `setState` aqui.

### 5.7 Binds (registro no get_it)

**Arquivo**: `lib/modules/invoice/invoice_binds.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:oflite/modules/invoice/data/datasource/invoice_remote_datasource.dart';
import 'package:oflite/modules/invoice/data/repository/invoice_repository_impl.dart';
import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/modules/invoice/presenter/invoice_list/invoice_list_view_model.dart';

void registerInvoiceDependencies(GetIt sl) {
  sl.registerLazySingleton<InvoiceRemoteDataSource>(
    () => InvoiceRemoteDataSource(),
  );
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(sl<InvoiceRemoteDataSource>()),
  );

  // ViewModels sempre factory!
  sl.registerFactory<InvoiceListViewModel>(
    () => InvoiceListViewModel(),
  );
}
```

### 5.8 Routes (exposição de rotas)

**Arquivo**: `lib/modules/invoice/invoice_routes.dart`

> **Obrigatório para todo módulo que possui `presenter/` (View).**

```dart
import 'package:flutter/material.dart';
import 'presenter/invoice_list/invoice_list_view.dart';

enum InvoiceRoute {
  invoiceList,
  invoiceCreator,
}

extension InvoiceRouteExtension on InvoiceRoute {
  String get path {
    switch (this) {
      case InvoiceRoute.invoiceList:
        return '/invoices';
      case InvoiceRoute.invoiceCreator:
        return '/invoices/create';
    }
  }
}

final Map<String, WidgetBuilder> invoiceRoutes = {
  InvoiceRoute.invoiceList.path: (_) => const InvoiceListView(),
};
```

### 5.9 Registrar no app

1. **Adicione no `injection.dart`**:
   ```dart
   import 'package:oflite/modules/invoice/invoice_binds.dart';
   // ...
   registerInvoiceDependencies(getIt);
   ```

2. **Adicione no `app_routes.dart`**:
   ```dart
   import 'package:oflite/modules/invoice/invoice_routes.dart';
   // ...
   final Map<String, WidgetBuilder> appRoutes = {
     ...invoiceRoutes,
     // outros módulos...
   };
   ```

---

## 6. UseCases — Quando e Como Criar

### 6.1 O que é um UseCase?

Um **UseCase** encapsula **uma única ação de negócio** que pode envolver:
- Orquestração de múltiplos repositórios
- Lógica complexa de transformação de dados
- Regras de negócio que não cabem nem no Repository nem no ViewModel

Ele é **independente de UI** (não conhece widgets, context ou `ChangeNotifier`) e **independente de fonte de dados** (não conhece Firebase, HTTP, etc.).

### 6.2 Quando CRIAR um UseCase?

| Situação | Exemplo no projeto |
|----------|-------------------|
| **Orquestração multi-repo** | `CreateBudgetFromChatUsecase` usa `ChatBudgetRepository` + `ChatScriptRepository` |
| **Lógica pesada de transformação** | `PdfGenerateUseCase` monta um PDF completo com tabelas, grids, imagens e formatação |
| **Regra de negócio reutilizável** | Gerar um recibo em PDF exige cálculos de pagamento e layout — `PdfGenerateReceiptUseCase` |
| **Fluxo com múltiplos passos** | Chatbot: carregar script → criar rascunho → atualizar endereço → adicionar itens |
| **Testabilidade isolada** | Quando a lógica é complexa o suficiente para merecer testes unitários próprios |

### 6.3 Quando NÃO criar um UseCase?

| Situação | O que fazer em vez disso |
|----------|-------------------------|
| Operação CRUD simples (get, create, delete) | Chamar diretamente no ViewModel via `Repository` |
| Apenas repassar chamada para o Repository | Não adicionar camada intermediária desnecessária |
| Lógica puramente de UI (validação de campo, estado de loading) | Fica no **ViewModel** |
| Acesso direto a dados sem transformação | Chamar o **Repository** direto |

### 6.4 Onde o UseCase fica na arquitetura?

```
┌────────┐     ┌──────────┐     ┌──────────┐     ┌─────────────┐     ┌──────────┐
│  View  │────▶│ ViewModel │────▶│ UseCase  │────▶│ Repository  │────▶│DataSource│
└────────┘     └──────────┘     └──────────┘     └─────────────┘     └──────────┘
                                    (opcional)
```

> **Regra**: o UseCase é **opcional**. A maioria das telas simples não precisa. Use quando a lógica de negócio justificar a separação.

### 6.5 Exemplo 1 — Orquestração Multi-Repo (`CreateBudgetFromChatUsecase`)

**Arquivo**: `lib/modules/chat_budget/domain/usecase/create_budget_from_chat_usecase.dart`

```dart
import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/entity/chat_script_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_script_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/items_budget.dart';

/// Orquestra a criação completa de um orçamento via chat.
///
/// Responsável por carregar o script e executar os passos do fluxo
/// conforme interação do usuário, delegando I/O ao [ChatBudgetRepository].
class CreateBudgetFromChatUsecase {
  final ChatBudgetRepository _chatRepo;
  final ChatScriptRepository _scriptRepo;

  const CreateBudgetFromChatUsecase(this._chatRepo, this._scriptRepo);

  /// Script atual (fallback incluído).
  ChatScriptEntity? get script => _scriptRepo.currentScript;

  /// Garante que o script está carregado.
  Future<Result<ChatScriptEntity>> ensureScriptLoaded() async {
    final current = _scriptRepo.currentScript;
    if (current != null) return Result.ok(current);
    return _scriptRepo.fetchScript();
  }

  /// Cria o orçamento vazio a partir do nome do cliente.
  Future<Result<CustomerInfo>> createDraft(
    String clientName, {
    String? phone,
  }) async {
    return _chatRepo.createDraftBudget(clientName, phone: phone);
  }

  /// Atualiza endereço completo no rascunho.
  Future<Result<void>> updateAddress({
    String? street,
    String? city,
    String? neighborhood,
    String? zip,
  }) async {
    return _chatRepo.updateDraftAddress(
      street: street,
      city: city,
      neighborhood: neighborhood,
      zip: zip,
    );
  }

  /// Adiciona um item (produto ou serviço) ao rascunho.
  Future<Result<void>> addItem(ItemsBudget item) async {
    return _chatRepo.addDraftItem(item);
  }

  /// Finaliza e salva o orçamento completo.
  Future<Result<CustomerInfo>> finalizeBudget() async {
    return _chatRepo.finalizeDraft();
  }
}
```

> **Por que é UseCase?** Precisa coordenar **dois repositórios diferentes** (`ChatBudgetRepository` e `ChatScriptRepository`) e orquestrar um fluxo em múltiplos passos. O ViewModel não deveria saber dessa complexidade.

### 6.6 Exemplo 2 — Lógica Pesada Sem Repo (`PdfGenerateUseCase`)

**Arquivo**: `lib/modules/pdf/domain/usecase/pdf_generate_usecase.dart`

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/shared/models/observation_pdf.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Geração do PDF do orçamento (dados do titular, tabela de produtos,
/// tabela de serviços e observações).
class PdfGenerateUseCase {
  final ConvertCoinRepository _moneyConvert;

  PdfGenerateUseCase(this._moneyConvert);

  Future<String> patternPDF({
    required int countService,
    required int countProduct,
    required String totalPriceBudget,
    required String totalPriceProducts,
    required String totalPriceServices,
    required List<ItemsBudget> items,
    required CustomerInfo customer,
    required OwnerPdf owner,
    required List<ObservationPdf> observations,
    String? authToken,
  }) async {
    final PdfDocument document = await _buildDocument(
      countService: countService,
      countProduct: countProduct,
      // ...
    );

    // Desenha logo, grids, tabelas, observações...
    // Lógica de 800+ linhas de layout de PDF

    final String localFile = await _saveDocument(document);
    document.dispose();
    return localFile;
  }

  Future<String> _saveDocument(PdfDocument document) async {
    final List<int> bytes = await document.save();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/orçamento.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }
}
```

> **Por que é UseCase?** Não acessa banco de dados diretamente, mas contém **lógica pesada de negócio** (layout de PDF com tabelas, cálculo de posições, renderização de imagens). Isolar isso facilita testes e mantém o ViewModel enxuto.

### 6.7 Exemplo 3 — Recibo em PDF (`PdfGenerateReceiptUseCase`)

**Arquivo**: `lib/modules/pdf/domain/usecase/pdf_generate_receipt_usecase.dart`

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/models/payment_customer.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Geração do PDF do recibo (dados do titular, dados do orçamento,
/// dados do recibo e tabela de pagamentos realizados).
class PdfGenerateReceiptUseCase {
  final ConvertCoinRepository _moneyConvert;

  PdfGenerateReceiptUseCase(this._moneyConvert);

  Future<String> patternPDF({
    required List<PaymentCustomer> paymentList,
    required Receipt recived,
    required String totalPriceBudget,
    required CustomerInfo customer,
    required OwnerPdf owner,
  }) async {
    final PdfDocument document = _createDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    final double sizeWithImage = await _drawLogo(page, owner);
    _drawOwnerGrid(page, owner, sizeWithImage);
    _drawReceiptTitle(page, graphics);
    final double count = _drawBudgetDataGrid(page, customer);
    _drawReceiptInfoGrid(page, recived);
    _drawPaymentsSectionTitle(page, graphics, count);

    if (paymentList.isNotEmpty) {
      _drawPaymentsTable(
        page: page,
        count: count,
        paymentList: paymentList,
        totalPriceBudget: totalPriceBudget,
      );
    }

    final String localFile = await _saveDocument(document);
    document.dispose();
    return localFile;
  }
}
```

> **Por que é UseCase?** Reutiliza a mesma justificativa do PDF de orçamento: lógica complexa, pura transformação de dados em documento, sem acesso direto a DataSource.

### 6.8 Como registrar um UseCase no `binds`?

UseCases recebem dependências via construtor e são registrados como **`registerFactory`** (se precisar de estado fresco) ou **`registerLazySingleton`** (se forem stateless e reutilizáveis):

```dart
// Exemplo no chat_budget_binds.dart:
sl.registerFactory<CreateBudgetFromChatUsecase>(
  () => CreateBudgetFromChatUsecase(
    sl<ChatBudgetRepository>(),
    sl<ChatScriptRepository>(),
  ),
);

// Exemplo no pdf_binds.dart:
sl.registerFactory<PdfGenerateUseCase>(
  () => PdfGenerateUseCase(sl<ConvertCoinRepository>()),
);
sl.registerFactory<PdfGenerateReceiptUseCase>(
  () => PdfGenerateReceiptUseCase(sl<ConvertCoinRepository>()),
);
```

> **Dica**: UseCases podem ser chamados tanto no **ViewModel** quanto dentro de outro **UseCase** (composição).

---

## 7. A Pasta `modules/core/` — Serviços Transversais

Diferentemente dos módulos de **feature** (budget, payment, receipt...), os módulos em `core/` **não possuem UI** (pastas `presenter/` e `view/`).

Eles expõem apenas:
- `{service}_binds.dart`
- `domain/repository/{service}_repository.dart`
- `data/repository/{service}_repository_impl.dart`
- **`data/datasource/{service}_remote_datasource.dart` quando acessam fonte externa** (SDKs, Firebase, HTTP)

### Exemplo: `share_link` (tem datasource — fonte externa)

```
core/share_link/
├── share_link_binds.dart
├── domain/repository/share_link_repository.dart
└── data/
    ├── datasource/share_link_datasource.dart
    └── repository/share_link_repository_impl.dart
```

### Exemplo: `convert_coin` (sem datasource — pura lógica local)

```
core/convert_coin/
├── convert_coin_binds.dart
├── domain/repository/convert_coin_repository.dart
└── data/repository/convert_coin_repository_impl.dart
```

**Quando usar `core/`**: serviços reutilizáveis por vários módulos — anúncios, conversão de moeda, loading global, alerts, CEP, notificações, compras in-app, etc.

---

## 8. Resumo das Regras de Ouro

| # | Regra |
|---|-------|
| 1 | Sempre separar em camadas: `data/` → `domain/` → `presenter/` |
| 2 | ViewModel estende `ChangeNotifier` e nunca acessa widgets/context |
| 3 | View só conversa com o ViewModel (nunca com Repository direto) |
| 4 | ViewModels registrados como `registerFactory` no get_it |
| 5 | Repositórios e DataSources como `registerLazySingleton` |
| 6 | DataSource trabalha apenas com `Map<String, dynamic>` / tipos primitivos |
| 7 | UseCase só existe quando há lógica de negócio complexa ou orquestração multi-repo |
| 8 | UseCase é independente de UI e de fonte de dados |
| 9 | Usar `Result<T, E>` (quando aplicável) para fluxos de erro |
| 10 | Componentes (widgets) ficam em `presenter/components/` ou subpastas |
| 11 | Modais ficam em `presenter/components/modals/` |
| 12 | Strings centralizadas em `shared/common/strings/` |
| 13 | Modelos compartilhados em `shared/models/` |
| **14** | **Todo módulo que tem `presenter/` (tela) deve expor `{module}_routes.dart`** |
| **15** | **Todo módulo `core/` que acessa fonte externa deve ter `data/datasource/`** |

---

## 9. Módulos Existentes (checklist)

### Features com Router + ViewModel + View
- [x] `budget` — Orçamentos (list, creator, items, tab)
- [x] `chat_budget` — Assistente de orçamento por chat
- [x] `comment` — Comentários nos orçamentos
- [x] `dashboard` — Dashboard com gráficos
- [x] `image` — Edição de imagens/logo
- [x] `login` — Autenticação
- [x] `main_config_menu` — Menu de configurações
- [x] `main_tab` — Navegação principal (Bottom/Tab bar)
- [x] `payment` — Pagamentos/pagamentos de orçamento
- [x] `pdf` — Geração e visualização de PDFs
- [x] `product` — Produtos e preços
- [x] `receipt` — Recibos
- [x] `singup` — Cadastro de usuário
- [x] `subscription` — Assinaturas/Planos
- [x] `terms_conditions` — Termos de uso
- [x] `web_budget` — Orçamento público web (compartilhável)

### Core — com DataSource (fonte externa)
- [x] `core/ads` — Google Mobile Ads
- [x] `core/cep` — Consulta de CEP
- [x] `core/in_app_purchase` — Compras dentro do app
- [x] `core/notification` — Push/local notifications
- [x] `core/share_link` — Compartilhamento de links

### Core — sem DataSource (lógica local / pura)
- [x] `core/convert_coin` — Conversão de moeda (formatação `intl`)
- [x] `core/display_alert` — SnackBars/Alerts globais
- [x] `core/loading_event` — Loading global

---

## 10. Dicas Rápidas

### Adicionar um novo campo no formulário
1. Atualizar o modelo em `shared/models/`
2. Atualizar o DataSource para persistir o novo campo
3. Atualizar o ViewModel (validação/lógica)
4. Atualizar a View (novo widget de input)
5. Atualizar o componente de PDF se necessário

### Criar um modal de ações
1. Criar em `presenter/components/modals/{nome}_bottom_modal_widget.dart`
2. Usar `showModalBottomSheet` na View
3. O callback de ação chama um método no ViewModel

### Expor uma nova rota
1. Adicionar no enum `BudgetRoute` (ou módulo correspondente)
2. Adicionar no `Map<String, WidgetBuilder>` do módulo
3. Registrar no `app_routes.dart`
4. Navegar com `Navigator.pushNamed(context, BudgetRoute.budgetCreator.path)`

### Criar um novo UseCase
1. Criar classe em `modules/{modulo}/domain/usecase/{acao}_{feature}_usecase.dart`
2. Receber dependências no construtor (repositórios ou outros usecases)
3. Implementar o método principal com a lógica de negócio
4. Retornar `Result<T, E>` quando houver fluxo de erro
5. Registrar no `{modulo}_binds.dart`
6. Injetar no ViewModel via `getIt<MeuUseCase>()`

### Criar um módulo core com datasource
1. Criar `data/datasource/{service}_remote_datasource.dart`
2. Mover todo acesso ao SDK externo (Firebase, HTTP, plugin) para o DataSource
3. Manter o RepositoryImpl como orquestrador (estado, callbacks, regras)
4. Registrar DataSource antes do Repository no `{service}_binds.dart`
5. Injetar DataSource no RepositoryImpl via construtor

---

> **Documento mantido na pasta `.pi/`** — atualizar sempre que novos padrões forem adotados.
