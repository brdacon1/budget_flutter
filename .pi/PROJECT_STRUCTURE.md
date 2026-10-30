# 📁 Estrutura do Projeto — OFLite (Budget Flutter)

> **Arquitetura**: MVVM + Clean Architecture (simplificada)
> **Gerenciamento de Estado**: `ChangeNotifier` (Provider pattern) + `get_it` (Injeção de Dependência)
> **Roteamento**: `MaterialPageRoute` + Map de rotas estáticas

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
│   │   │   └── repository/
│   │   │       └── budget_repository.dart
│   │   └── presenter/
│   │       ├── budget_list/
│   │       │   ├── budget_list_view.dart
│   │       │   ├── budget_list_view_model.dart
│   │       │   └── components/
│   │       ├── budget_creator/
│   │       ├── budget_list_items/
│   │       └── budget_tab/
│   │
│   ├── core/                          # 🔷 Serviços transversais (sem UI)
│   │   ├── ads/
│   │   ├── cep/
│   │   ├── convert_coin/
│   │   ├── display_alert/
│   │   ├── in_app_purchase/
│   │   ├── loading_event/
│   │   ├── notification/
│   │   └── share_link/
│   │       ├── share_link_binds.dart
│   │       ├── domain/repository/
│   │       └── data/
│   │
│   ├── login/
│   ├── payment/
│   ├── pdf/
│   ├── product/
│   ├── receipt/
│   ├── subscription/
│   ├── chat_budget/
│   ├── dashboard/
│   ├── web_budget/
│   └── ...
│
└── shared/
    ├── common/
    │   ├── constants/        # (constants.dart, environment.dart, etc.)
    │   ├── enums/            # AlertTypeEnum, ReceiptFieldEnum...
    │   ├── strings/          # Strings centralizadas
    │   ├── utils/            # Helpers puros
    │   ├── widgets/          # Widgets reutilizáveis globais
    │   └── controllers/      # Controllers globais (ex: MenuControllerApp)
    ├── design_pattern/
    │   ├── command.dart
    │   └── result.dart       # Result<T, E> para tratamento de erro
    └── models/               # Modelos/Entidades compartilhados
        ├── customer_info.dart
        ├── items_budget.dart
        ├── receipt.dart
        └── ...
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
| Binds | `{module}_binds.dart` | `budget_binds.dart` |
| Routes | `{module}_routes.dart` | `budget_routes.dart` |
| UseCase | `{acao}_{feature}_usecase.dart` | `create_budget_from_chat_usecase.dart` |

---

## 3. Como Funciona o Gerenciamento de Estado

### 3.1 Stack tecnológica
- **`get_it`**: Injeção de dependências (Service Locator)
- **`ChangeNotifier`**: Notificação de mudanças de estado (classe nativa do Flutter)
- **Padrão Observer**: A View escuta o ViewModel via `addListener` / `notifyListeners`

### 3.2 Ciclo de vida

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  ViewModel  │────▶│  notify()   │────▶│    View     │
│  (estado)   │     │  listeners  │     │  (rebuild)  │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                                      │
       └────────── Ação do usuário ───────────┘
```

### 3.3 Regras do `injection.dart`

| Tipo | Registro | Motivo |
|------|----------|--------|
| DataSources | `registerLazySingleton` | Compartilhado, mantém cache de conexão |
| Repositories | `registerLazySingleton` | Mantém cache em memória |
| ViewModels | `registerFactory` | Sempre nova instância ao abrir a tela |

---

## 4. Como Criar um Módulo (passo a passo)

> Exemplo criando um módulo fictício chamado `invoice` (notas fiscais).

### 4.1 Criar a árvore de pastas

```bash
mkdir -p lib/modules/invoice/data/datasource
mkdir -p lib/modules/invoice/data/repository
mkdir -p lib/modules/invoice/domain/repository
mkdir -p lib/modules/invoice/presenter/invoice_list/components
mkdir -p lib/modules/invoice/presenter/invoice_creator/components
```

### 4.2 Interface do Repository (camada Domain)

**Arquivo**: `lib/modules/invoice/domain/repository/invoice_repository.dart`

```dart
abstract class InvoiceRepository {
  Future<List<Invoice>> fetchInvoices(String userId);
  Future<void> createInvoice(Invoice invoice);
  Future<void> deleteInvoice(String id);
}
```

### 4.3 DataSource (camada Data — fonte remota)

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

### 4.4 Repository Implementation (camada Data)

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

### 4.5 ViewModel (camada Presenter)

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

### 4.6 View (camada Presenter — tela)

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

### 4.7 Binds (registro no get_it)

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

### 4.8 Routes (exposição de rotas)

**Arquivo**: `lib/modules/invoice/invoice_routes.dart`

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

### 4.9 Registrar no app

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

## 5. A Pasta `modules/core/` — Serviços Transversais

Diferentemente dos módulos de **feature** (budget, payment, receipt...), os módulos em `core/` **não possuem UI** (pastas `presenter/` e `view/`).

Eles expõem apenas:
- `{service}_binds.dart`
- `domain/repository/{service}_repository.dart`
- `data/repository/{service}_repository_impl.dart`

> Exceções raras: `data/datasource/` se houver fonte externa (ex: `cep_remote_datasource.dart`).

### Exemplo: `share_link`

```
core/share_link/
├── share_link_binds.dart
├── domain/repository/share_link_repository.dart
└── data/
    ├── datasource/share_link_datasource.dart
    └── repository/share_link_repository_impl.dart
```

**Quando usar `core/`**: serviços reutilizáveis por vários módulos — anúncios, conversão de moeda, loading global, alerts, CEP, notificações, compras in-app, etc.

---

## 6. Resumo das Regras de Ouro

| # | Regra |
|---|-------|
| 1 | Sempre separar em camadas: `data/` → `domain/` → `presenter/` |
| 2 | ViewModel estende `ChangeNotifier` e nunca acessa widgets/context |
| 3 | View só conversa com o ViewModel (nunca com Repository direto) |
| 4 | ViewModels registrados como `registerFactory` no get_it |
| 5 | Repositórios e DataSources como `registerLazySingleton` |
| 6 | Usar `Result<T, E>` (quando aplicável) para fluxos de erro |
| 7 | Componentes (widgets) ficam em `presenter/components/` ou `presenter/{subfeature}/components/` |
| 8 | Modais ficam em `presenter/components/modals/` |
| 9 | Strings centralizadas em `shared/common/strings/` |
| 10 | Modelos compartilhados em `shared/models/` |

---

## 7. Módulos Existentes (checklist)

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
- [x] `core/ads` — Google Mobile Ads
- [x] `core/cep` — Consulta de CEP
- [x] `core/convert_coin` — Conversão de moeda
- [x] `core/display_alert` — SnackBars/Alerts globais
- [x] `core/in_app_purchase` — Compras dentro do app
- [x] `core/loading_event` — Loading global
- [x] `core/notification` — Push/local notifications
- [x] `core/share_link` — Compartilhamento de links

---

## 8. Dicas Rápidas

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
