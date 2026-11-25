# 📁 Estrutura do Projeto — OFLite (Budget Flutter)

> **Arquitetura**: MVVM + Clean Architecture (simplificada)
> **Gerenciamento de Estado**: `ChangeNotifier` (Provider pattern) + `get_it`
> (Injeção de Dependência)
> **Roteamento**: `MaterialPageRoute` + Map de rotas estáticas
> **Visual**: [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) — fonte única de cores,
> tipografia, raios, espaçamentos e componentes (obrigatório em toda tela)
> **Responsivo/Tablet**: [`TABLET_RESPONSIVE_PLAN.md`](TABLET_RESPONSIVE_PLAN.md)
> e §22 deste arquivo

---

## 0. Ponytail — Regra de Ouro do Projeto

Este projeto segue o modo **ponytail full**: *o menor código completo que
resolve o problema*.

- **Não** adicionamos abstração, wrapper, conversão de tipo ou configuração que
  ninguém pediu.
- **Não** criamos datasource em core que é puramente local (ex: `loading_event`).
- **Criamos** datasource em core que acessa **fonte externa** (SDK de terceiros,
  Firebase, API REST).
- O shortest working diff vence. Deletar > adicionar.

Para detalhes
completos: <https://github.com/DietrichGebert/ponytail/blob/main/skills/ponytail/SKILL.md>

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
│   │   ├── loading_event/             # Loading local (sem datasource)
│   │   ├── in_app_purchase/           # Loja Google/Apple (tem datasource — SDK externo)
│   │   ├── notification/              # FCM + local notifications (tem datasource — SDK externo)
│   │   ├── cep/                       # Consulta externa (tem datasource)
│   │   ├── share_link/                # Compartilhamento (tem datasource)
│   │   ├── crashlytics/               # Firebase Crashlytics (tem datasource — SDK externo, mobile only)
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
│   ├── web_budget/                    # 🌐 Fluxo Web público do orçamento (ver seção 16)
│   ├── delete_account/                # 🌐 Exclusão de conta (Web — /delete-account)
│   ├── support/                       # 🌐 Suporte via WhatsApp (Web — /support, Support URL da App Store)
│   ├── legal/                         # 🌐 EULA + Política de Privacidade pt/en (Web — ver 16.8)
│   └── ...
│
└── shared/
    ├── common/
    ├── design_pattern/
    └── models/
```

---

## 2. Convenções de Nomenclatura

| Tipo                   | Padrão                                      | Exemplo                                       |
|------------------------|---------------------------------------------|-----------------------------------------------|
| View (página)          | `{feature}_view.dart`                       | `budget_list_view.dart`                       |
| ViewModel              | `{feature}_view_model.dart`                 | `budget_list_view_model.dart`                 |
| Componente             | `{feature}_{nome}.dart`                     | `budget_list_card.dart`                       |
| Modal simples          | `{feature}_{acao}_bottom_modal_widget.dart` | `budget_list_delete_bottom_modal_widget.dart` |
| Modal complexo (tela)  | `presenter/{modal}/{modal}_view.dart` + `_view_model.dart` | `budget_item_quantity_view.dart` (ver §19) |
| Strings do módulo      | `{modulo}_pt_string.dart`                   | `login_pt_string.dart`                        |
| DataSource             | `{feature}_remote_datasource.dart`          | `budget_remote_datasource.dart`               |
| Repository (impl)      | `{feature}_repository_impl.dart`            | `budget_repository_impl.dart`                 |
| Repository (interface) | `{feature}_repository.dart`                 | `budget_repository.dart`                      |
| UseCase                | `{acao}_{feature}_usecase.dart`             | `create_budget_from_chat_usecase.dart`        |
| Binds                  | `{module}_binds.dart`                       | `budget_binds.dart`                           |
| Routes                 | `{module}_routes.dart`                      | `budget_routes.dart`                          |
| Strings do módulo      | `{module}_pt_string.dart`                   | `login_pt_string.dart`                        |

---

## 2.1 Componentes de UI (Widgets) — Regra de Separação

> ⛔ **PROIBIDO — sem exceção:** widget grande ou complexo **JAMAIS** é criado
> dentro do arquivo da tela. Todo `StatelessWidget`/`StatefulWidget` que não
> seja a própria tela vai para `presenter/{tela}/components/`, um por arquivo,
> classe pública. Na View só cabem métodos `_build…()` pequenos e simples
> (poucas linhas, sem estado) usados apenas naquela tela. Na dúvida, é
> componente. Exemplo de erro já cometido: `_ManualAddressForm` e
> `_EditAwareInputBar` dentro de `chat_assistant_view.dart` (corrigido —
> hoje em `chat_assistant/components/`).

> **NÃO** crie widgets no formato de classe privada (`class _MeuWidget`) dentro
> das Views. Qualquer widget que não seja a própria tela deve ser extraído para
> um arquivo separado dentro de `presenter/{tela}/components/`.

### Regras

| # | Regra |
|---|-------|
| 1 | **Nenhum `class _AlgumaCoisa extends StatelessWidget/StatefulWidget` dentro de `{feature}_view.dart`**. A View deve conter apenas a tela e seu `State`. |
| 2 | Se um widget é usado apenas dentro de uma tela, crie-o em `presenter/{tela}/components/{nome}.dart` |
| 3 | Se um widget é reutilizado por mais de uma tela do mesmo módulo, coloque-o em `presenter/components/` do módulo |
| 4 | O nome do arquivo segue o padrão da convenção: `{feature}_{nome}.dart` (ex: `login_tab.dart`) |
| 5 | A classe deve ser **pública** (`class LoginTab extends StatelessWidget`) e receber dependências via construtor |

### Exemplo do que NÃO fazer

```dart
// login_view.dart
class _LoginTab extends StatelessWidget {
  const _LoginTab({required this.viewModel, ...});
  ...
}
```

### Exemplo do que FAZER

```dart
// lib/modules/auth/presenter/login/components/login_tab.dart
import 'package:flutter/material.dart';

class LoginTab extends StatelessWidget {
  const LoginTab({
    super.key,
    required this.viewModel,
    required this.onForgotPassword,
    required this.onGoogleLogin,
  });

  final LoginViewModel viewModel;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoogleLogin;

  @override
  Widget build(BuildContext context) {
    return Column(...);
  }
}
```

E na `login_view.dart`:

```dart
import 'package:oflite/modules/auth/presenter/login/components/login_tab.dart';

// ...
firstChild: LoginTab(
  viewModel: _viewModel,
  onForgotPassword: () => ...,
  onGoogleLogin: () => ...,
),
```

> **Motivo**: widgets privados dentro da View dificultam testes, reutilização e
> leitura do arquivo. Manter cada widget em seu próprio arquivo favorece o
> princípio da responsabilidade única e alinha a arquitetura modular do
> projeto.

---

## 3. O DataSource — Papel, Regras e Exemplo Real

### 3.1 O que é o DataSource?

O **DataSource** é a classe que **fala diretamente com o mundo externo**:</br>
`FirebaseFirestore`, `FirebaseAuth`, `http` (APIs REST), `SharedPreferences`,
`FirebaseStorage`, SDKs de terceiros (Google Mobile Ads, in_app_purchase,
etc.), sensores do celular.

Ele **não conhece** models de negócio, entidades ou regras do domínio. Sua única
responsabilidade é **trocar dados brutos** (`Map<String, dynamic>`, `String`,
`Uint8List`, etc.) com a fonte externa.

### 3.2 O que o DataSource NÃO faz?

| ❌ NÃO faz                         | ✅ Quem faz              |
|------------------------------------|--------------------------|
| Converter JSON → Model/Entity      | `RepositoryImpl`         |
| Validar regras de negócio          | `ViewModel` ou `UseCase` |
| Acessar `BuildContext` ou widgets  | `View` (Widget)          |
| Conter lógica de apresentação (UI) | `View`                   |
| Conter `ChangeNotifier`            | `ViewModel`              |

### 3.3 Regras de Ouro do DataSource

1. **Retorna/tipifica apenas tipos primitivos ou `Map<String, dynamic>`** —
   nunca models do domínio.
2. **Não lança exceções customizadas de negócio** — pode lançar exceções
   técnicas (FirebaseException, SocketException, etc.) que serão tratadas pelo
   Repository ou UseCase.
3. **É injetado no RepositoryImpl** — a ViewModel nunca vê o DataSource.
4. **Permite mock no construtor** — aceitar a instância externa (ex:
   `FirebaseFirestore? firestore`) facilita testes unitários.

### 3.4 Quando um módulo `core/` PRECISA de DataSource?

| Módulo                 | Fonte externa?                     | DataSource? |
|------------------------|------------------------------------|-------------|
| `core/cep`             | Sim (API ViaCep)                   | ✅ Sim      |
| `core/share_link`      | Sim (Firebase Dynamic Links / SDK) | ✅ Sim      |
| `core/ads`             | Sim (Google Mobile Ads SDK)        | ✅ Sim      |
| `core/in_app_purchase` | Sim (Google Play / App Store SDK)  | ✅ Sim      |
| `core/notification`    | Sim (FCM + Firestore)              | ✅ Sim      |
| `core/crashlytics`     | Sim (Firebase Crashlytics SDK)     | ✅ Sim      |
| `core/convert_coin`    | Não (pura formatação `intl`)       | ❌ Não      |
| `core/loading_event`   | Não (dialog local)                 | ❌ Não      |

> **Regra**: se o módulo `core/` acessa qualquer SDK externo, Firebase, HTTP ou
> storage, ele **deve** ter `data/datasource/`.

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

> **Observe**: o DataSource expõe métodos como `getBudgets()`, `saveBudget()`,
> `deleteBudgetItem()`, mas trabalha **exclusivamente** com
> `Map<String, dynamic>`
> e tipos nativos (`String`, `void`).

---

## 4. Como Funciona o Gerenciamento de Estado

### 4.1 Stack tecnológica

- **`get_it`**: Injeção de dependências (Service Locator)
- **`ChangeNotifier`**: Notificação de mudanças de estado (classe nativa do
  Flutter)
- **Padrão Observer**: A View escuta o ViewModel via `addListener` /
  `notifyListeners`

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

| Tipo         | Registro                | Motivo                                 |
|--------------|-------------------------|----------------------------------------|
| DataSources  | `registerLazySingleton` | Compartilhado, mantém cache de conexão |
| Repositories | `registerLazySingleton` | Mantém cache em memória                |
| ViewModels   | `registerFactory`       | Sempre nova instância ao abrir a tela  |

---

## 4.4 Padrão Command para Ações Assíncronas

> Quando um botão (ou qualquer interação da UI) dispara uma operação
> **assíncrona** que depende de espera (ex: salvar no Firestore, chamar API,
> gerar
> PDF), o ViewModel **não expõe o `Future` cru** para a View. Em vez disso,
> encapsula essa ação em um **`Command`**.

O `Command` é um `ChangeNotifier` especializado que controla o ciclo de vida de
uma ação async, evitando cliques duplos e expondo estados reativos:

| Estado      | Tipo         | Significado                                     |
|-------------|--------------|-------------------------------------------------|
| `running`   | `bool`       | A ação está em execução (bloqueia novo disparo) |
| `completed` | `bool`       | A ação terminou com sucesso (`Result` é `Ok`)   |
| `error`     | `bool`       | A ação terminou com erro (`Result` é `Error`)   |
| `result`    | `Result<T>?` | O resultado embrulhado em `Result<T>`           |

### Implementação na ViewModel

A ViewModel declara o `Command` no construtor, apontando-o para um método
protegido que retorna `Future<Result<T>>`:

```dart
import 'package:flutter/foundation.dart';
import 'package:oflite/shared/design_pattern/result.dart';

// --- na ViewModel ---
class BudgetCreateViewModel extends ChangeNotifier {
  final BudgetRepository _repository;

  BudgetCreateViewModel(this._repository) {
    saveBudgetCommand = Command0(_executeSaveBudget);
  }

  late final Command0<void> saveBudgetCommand;

  Future<Result<void>> _executeSaveBudget() async {
    // lógica de negócio + chamada ao repository
    return _repository.createBudget(/* dados */);
  }
}
```

> **Regra**: o método executado pelo `Command` (ex: `_executeSaveBudget`) deve
> ser **protegido** (`private`) e retornar sempre `Future<Result<T>>`. A
> ViewModel
> pode expor outros métodos `public` para manipular estado local, mas **a ação
que dispara espera deve passar pelo `Command`**.

### Implementação na View

Na View, escutamos o `Command` via `addListener` e reagimos aos estados
(loading, sucesso, erro):

```dart
class _BudgetCreateViewState extends State<BudgetCreateView> {
  late final BudgetCreateViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<BudgetCreateViewModel>();
    _viewModel.saveBudgetCommand.addListener(_onSaveBudgetChanged);
  }

  @override
  void dispose() {
    _viewModel.saveBudgetCommand.removeListener(_onSaveBudgetChanged);
    super.dispose();
  }

  void _onSaveBudgetChanged() {
    final cmd = _viewModel.saveBudgetCommand;

    if (cmd.completed) {
      // sucesso: navegar, mostrar snackbar, etc.
      Navigator.pop(context);
    } else if (cmd.error) {
      // erro: extrair mensagem de cmd.result
      // NUNCA SnackBar cru — use o padrão do app (ver §18)
      AlertSnackBar.error(
        context,
        'Não foi possível salvar',
        'Verifique sua conexão e tente novamente.',
      );
    }
    // quando running == true, o próprio build mostra loading no botão
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: /* ... */,
      floatingActionButton: FloatingActionButton(
        onPressed: _viewModel.saveBudgetCommand.running
            ? null // bloqueia clique enquanto executa
            : _viewModel.saveBudgetCommand.execute,
        child: _viewModel.saveBudgetCommand.running
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
      ),
    );
  }
}
```

### Regras de Ouro do Command

1. **Todo botão que dispara operação async deve usar `Command`** — nunca exponha
   `Future<void> metodo()` direto para a View.
2. **A View escuta o `Command`, não chama `await` diretamente** — o
   `addListener` permite reação desacoplada.
3. **O `Command` impede cliques duplos** — enquanto `running == true`, novas
   chamadas a `execute()` são ignoradas.
4. **O `Command` sempre retorna `Result<T>`** — sucesso (`Ok`) e erro (`Error`)
   são estados reativos, não exceções lançadas.
5. **Dispose dos listeners do `Command` na View** — assim como o `ViewModel`, o
   `Command` é um `ChangeNotifier` e precisa ter seus listeners removidos no
   `dispose()`.
6. **Use `Command0<T>` para ações sem parâmetro; `Command1<T, A>` para ações com
   1 argumento.** (Comandos com múltiplos argumentos devem usar um objeto/dto no
   lugar.)

### Exemplo de classe Command (referência)

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oflite/shared/design_pattern/result.dart';

typedef CommandAction0<T> = Future<Result<T>> Function();

abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  bool get error => _result is Error;
  bool get completed => _result is Ok;
  Result? get result => _result;

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(CommandAction0<T> action) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

class Command0<T> extends Command<T> {
  Command0(this._action);
  final CommandAction0<T> _action;

  Future<void> execute() async => _execute(_action);
}
```

---

## 5. Como Criar um Módulo (passo a passo)

> Exemplo criando um módulo fictício chamado `invoice` (notas fiscais).

### 5.1 Criar a árvore de pastas

```bash
mkdir -p lib/modules/invoice/data/datasource
mkdir -p lib/modules/invoice/data/repository
mkdir -p lib/modules/invoice/domain/repository
mkdir -p lib/modules/invoice/presenter/strings
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

**Arquivo**:
`lib/modules/invoice/data/datasource/invoice_remote_datasource.dart`

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

**Arquivo**:
`lib/modules/invoice/presenter/invoice_list/invoice_list_view_model.dart`

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

> **Importante**: ViewModels **sempre** extendem `ChangeNotifier`. Chamam
> `notifyListeners()` toda vez que o estado muda.

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

> **Regra**: A View **nunca** acessa o Repository diretamente. Só conversa com o
> ViewModel. A UI é reativa: o `addListener` chama `setState` aqui.

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

Ele é **independente de UI** (não conhece widgets, context ou `ChangeNotifier`)
e **independente de fonte de dados** (não conhece Firebase, HTTP, etc.).

### 6.2 Quando CRIAR um UseCase?

| Situação                           | Exemplo no projeto                                                                        |
|------------------------------------|-------------------------------------------------------------------------------------------|
| **Orquestração multi-repo**        | `CreateBudgetFromChatUsecase` usa `ChatBudgetRepository` + `ChatScriptRepository`         |
| **Lógica pesada de transformação** | `PdfGenerateUseCase` monta um PDF completo com tabelas, grids, imagens e formatação       |
| **Regra de negócio reutilizável**  | Gerar um recibo em PDF exige cálculos de pagamento e layout — `PdfGenerateReceiptUseCase` |
| **Fluxo com múltiplos passos**     | Chatbot: carregar script → criar rascunho → atualizar endereço → adicionar itens          |
| **Testabilidade isolada**          | Quando a lógica é complexa o suficiente para merecer testes unitários próprios            |
| **Regra de negócio isolada (mesmo pequena)** | `PdfSanitizeTextUsecase` (remove caracteres que a fonte do PDF não desenha) e `PdfAddWrappedRowsUsecase` (quebra texto longo em linhas da grade sem deixar página em branco) |

> **Regra de Ouro**: toda função que executa uma **regra de negócio** é um
> **UseCase** — classe em `domain/usecase/` do módulo dono, injetada por
> construtor e registrada no `{modulo}_binds.dart`. **Nunca** função solta
> (top-level) nem pasta `utils/` dentro do módulo.
> **Única exceção**: conversão/formatação pura de valor, sem regra de negócio
> (ex.: `lib/shared/common/utils/`) — essa pode ser função/utilitário.

### 6.3 Quando NÃO criar um UseCase?

| Situação                                                       | O que fazer em vez disso                         |
|----------------------------------------------------------------|--------------------------------------------------|
| Operação CRUD simples (get, create, delete)                    | Chamar diretamente no ViewModel via `Repository` |
| Apenas repassar chamada para o Repository                      | Não adicionar camada intermediária desnecessária |
| Lógica puramente de UI (validação de campo, estado de loading) | Fica no **ViewModel**                            |
| Acesso direto a dados sem transformação                        | Chamar o **Repository** direto                   |
| Chamada HTTP / download / SDK externo (ex.: baixar o logo)     | **DataSource** faz o I/O; o **RepositoryImpl** monta URL/token, devolve `Result` e **guarda em cache** (só busca de novo quando o dado muda) |

> **UseCase NÃO é wrapper de chamada HTTP.** UseCase existe para **regra de
> negócio** (ex.: gerar o PDF, editar um pedido). Ele **pode consumir** vários
> Repositories e outros UseCases injetados, mas **nunca** é criado só para
> embrulhar uma chamada de rede/I/O — isso é papel do RepositoryImpl +
> DataSource.
>
> ```dart
> // ❌ ERRADO — usecase só para baixar o logo
> class PdfLoadLogoUsecase { Future<PdfBitmap?> call(OwnerPdf o) => ... }
>
> // ✅ CERTO — a regra de negócio (gerar PDF) consome o repository direto;
> // o PdfRepositoryImpl baixa via PdfRemoteDataSource e mantém o logo em
> // cache até o `fotoId` mudar.
> class PdfGenerateBudgetSimpleUsecase {
>   final PdfRepository _pdfRepository;
>   ...
>   final logo = await _pdfRepository.fetchLogo(owner, authToken: authToken);
> }
> ```

### 6.4 Onde o UseCase fica na arquitetura?

```
┌────────┐     ┌──────────┐     ┌──────────┐     ┌─────────────┐     ┌──────────┐
│  View  │────▶│ ViewModel │────▶│ UseCase  │────▶│ Repository  │────▶│DataSource│
└────────┘     └──────────┘     └──────────┘     └─────────────┘     └──────────┘
                                    (opcional)
```

> **Regra**: o UseCase é **opcional**. A maioria das telas simples não precisa.
> Use quando a lógica de negócio justificar a separação.

### 6.5 Exemplo 1 — Orquestração Multi-Repo (`CreateBudgetFromChatUsecase`)

**Arquivo**:
`lib/modules/chat_budget/domain/usecase/create_budget_from_chat_usecase.dart`

```dart
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_script_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_script_repository.dart';
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

> **Por que é UseCase?** Precisa coordenar **dois repositórios diferentes**
> (`ChatBudgetRepository` e `ChatScriptRepository`) e orquestrar um fluxo em
> múltiplos passos. O ViewModel não deveria saber dessa complexidade.

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

> **Por que é UseCase?** Não acessa banco de dados diretamente, mas contém
> **lógica pesada de negócio** (layout de PDF com tabelas, cálculo de posições,
> renderização de imagens). Isolar isso facilita testes e mantém o ViewModel
> enxuto.

### 6.7 Exemplo 3 — Recibo em PDF (`PdfGenerateReceiptUseCase`)

**Arquivo**:
`../lib/modules/pdf/domain/usecase/pdf_generate_receipt/pdf_generate_receipt_usecase.dart`

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

> **Por que é UseCase?** Reutiliza a mesma justificativa do PDF de orçamento:
> lógica complexa, pura transformação de dados em documento, sem acesso direto a
> DataSource.

### 6.8 Como registrar um UseCase no `binds`?

UseCases recebem dependências via construtor e são registrados como **
`registerFactory`** (se precisar de estado fresco) ou **
`registerLazySingleton`** (se forem stateless e reutilizáveis):

```dart
// Exemplo no chat_assistant_binds.dart:
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

> **Dica**: UseCases podem ser chamados tanto no **ViewModel** quanto dentro de
> outro **UseCase** (composição).

---

## 7. A Pasta `modules/core/` — Serviços Transversais

Diferentemente dos módulos de **feature** (budget, payment, receipt...), os
módulos em `core/` **não possuem UI** (pastas `presenter/` e `view/`).

Eles expõem apenas:

- `{service}_binds.dart`
- `domain/repository/{service}_repository.dart`
- `data/repository/{service}_repository_impl.dart`
- **`data/datasource/{service}_remote_datasource.dart` quando acessam fonte
  externa** (SDKs, Firebase, HTTP)

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

**Quando usar `core/`**: serviços reutilizáveis por vários módulos — anúncios,
conversão de moeda, loading global, alerts, CEP, notificações, compras in-app,
etc.

---

## 8. Resumo das Regras de Ouro

| #      | Regra                                                                                                                                                    |
|--------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1      | Sempre separar em camadas: `data/` → `domain/` → `presenter/`                                                                                            |
| 2      | ViewModel estende `ChangeNotifier` e nunca acessa widgets/context                                                                                        |
| 3      | View só conversa com o ViewModel (nunca com Repository direto)                                                                                           |
| 4      | ViewModels registrados como `registerFactory` no get_it                                                                                                  |
| 5      | Repositórios e DataSources como `registerLazySingleton`                                                                                                  |
| 6      | DataSource trabalha apenas com `Map<String, dynamic>` / tipos primitivos                                                                                 |
| 7      | UseCase só existe quando há lógica de negócio complexa ou orquestração multi-repo                                                                        |
| 8      | UseCase é independente de UI e de fonte de dados                                                                                                         |
| 9      | Usar `Result<T, E>` (quando aplicável) para fluxos de erro                                                                                               |
| 10     | Componentes (widgets) ficam em `presenter/components/` ou subpastas. **NUNCA crie `class _AlgumaCoisa extends StatelessWidget/StatefulWidget` dentro da View** |
| 11     | Modais **simples** ficam em `presenter/components/modals/`. Modais **complexos** são **telas**: pasta própria com View + ViewModel + `components/` (§19) |
| 12     | **Strings ficam dentro do módulo, em `presenter/strings/{modulo}_pt_string.dart`**                                                                       |
| 13     | **Models/Entities de feature ficam no módulo dono (`data/model/` ou `domain/entity/`). `shared/models/` é EXCEÇÃO — só infra global (`Result<T>` etc.)** |
| **14** | **Todo módulo que tem `presenter/` (tela) deve expor `{module}_routes.dart`**                                                                            |
| **15** | **Todo módulo `core/` que acessa fonte externa deve ter `data/datasource/`**                                                                             |
| **16** | **Toda cor vem de `lib/shared/common/constants/colors.dart` — nunca `Color(0x...)` ou `Colors.*` direto no widget (ver seção 15)**                       |
| **17** | **Tela Web só existe se for registrada no `main_web.dart` (+ rewrite no `firebase.json`). Nada do app mobile é exposto no Web por padrão (ver seção 16)** |
| **18** | **Modal complexo é TELA: pasta própria com `{modal}_view.dart` + `{modal}_view_model.dart` + `components/` (um widget por arquivo). Só modal simples (sem usecase/repository, sem estado) dispensa ViewModel (ver seção 19)** |
| **19** | **IA opera o app só via tools que chamam UseCases. `firebase_ai` só no DataSource; o modelo nunca calcula; toda escrita é confirmada pelo usuário; falha da IA cai no modo padrão (ver seção 20)** |
| **20** | **Nenhuma URL/endpoint de fonte externa fora do DataSource (ex.: URL do Firebase Storage fica em `PdfRemoteDataSource.logoUrl`)** |
| **21** | **Single Source of Truth: cada dado tem UM dono (o Repository do módulo). View/ViewModel nunca chamam HTTP, Firebase ou `getIt<…Repository>()` por fora do fluxo UseCase → Repo → DataSource (ver seção 21)** |

---

## 9. Módulos Existentes (checklist)

### Features com Router + ViewModel + View

- [x] `budget` — Orçamentos (list, creator, items, tab)
- [x] `chat_assistant` — Assistente por chat (modo padrão + modo IA, ver §20)
- [x] `comment` — Comentários nos orçamentos
- [x] `comment_library` — Lista de comentários reutilizáveis com IA, só assinantes (nome gerado pela IA, "Melhorar com IA"; plano em `.pi/COMMENT_LIBRARY_PLAN.md`)
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
- [x] `subscription` — Assinaturas/Planos (mensal + anual; SKUs em `env/*.json`; guia de loja em `.pi/PREMIUM_SUBSCRIPTION_STORE_GUIDE.md`)
- [x] `terms_conditions` — Termos de uso
- [x] `web_budget` — Orçamento público web (compartilhável)
- [x] `delete_account` — Exclusão de conta (Web — `/delete-account`)
- [x] `support` — Suporte via WhatsApp (Web — `/support`)
- [x] `legal` — EULA + Política de Privacidade pt/en (Web — `/termos-de-uso`, `/politica-de-privacidade`, `/terms-of-use`, `/privacy-policy`)

### Core — com DataSource (fonte externa)

- [x] `core/ads` — Google Mobile Ads (exibe apenas para não-assinantes)
- [x] `core/ai_text` — Texto simples com Gemini (sem tools); limite 30/dia em `GenerateAiTextUsecase`
- [x] `core/app_check` — Firebase App Check (protege o Firebase AI Logic; mobile only)
- [x] `core/cep` — Consulta de CEP
- [x] `core/crashlytics` — Relatório de crashes (mobile only)
- [x] `core/in_app_purchase` — Compras dentro do app
- [x] `core/notification` — Push/local notifications
- [x] `core/share_link` — Compartilhamento de links

### Core — sem DataSource (lógica local / pura)

- [x] `core/convert_coin` — Conversão de moeda (formatação `intl`)
- [x] `core/loading_event` — Loading global

---

## 10. Regra de Ouro — Models e Entities SEMPRE Dentro do Módulo Dono

> **ESTA É A REGRA MAIS QUEBRADA DO PROJETO. SIGA À RISCA.**

### 10.1 Onde ficam

Seguindo o padrão do projeto de referência (Clean Architecture modular):

| Tipo                             | Pasta no módulo  | Exemplo                      |
|----------------------------------|------------------|------------------------------|
| **Entity** (domínio puro)        | `domain/entity/` | `budget_entity.dart`         |
| **Model** (DTO/JSON)             | `data/model/`    | `budget_response_model.dart` |
| **Model local** (estado simples) | `presenter/`     | `budget_list_state.dart`     |

```
lib/modules/budget/
├── data/
│   ├── model/           ← DTOs do budget (fromJson/toJson)
│   │   └── budget_response_model.dart
│   └── repository/
├── domain/
│   ├── entity/          ← Entidades puras do budget
│   │   └── budget_entity.dart
│   ├── repository/
│   ├── usecase/
│   └── ...
└── presenter/
```

### 10.2 Regras

| # | Regra                                                                                                                                                    |
|---|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 | **Model/Entity de feature = dentro do módulo**. NUNCA em `shared/models/`.                                                                               |
| 2 | Se `pdf` precisa de `CustomerInfo`, importa de `modules/budget/domain/entity/` (ou consome via UseCase/Repository).                                      |
| 3 | `shared/models/` é **reservada para infraestrutura genuinamente global** (`Result<T>`, patterns, etc.).                                                  |
| 4 | Não invente abstração: se tem `fromJson`/`toJson`, é **Model** em `data/model/`. Se é pura classe de negócio sem JSON, é **Entity** em `domain/entity/`. |
| 5 | Se um `core/` retorna dados, o model fica em `modules/core/{servico}/data/model/` ou `domain/entity/`.                                                   |

### 10.3 Model "usado por mais de um módulo"

Isso **NÃO** significa que ele vai para `shared/models/`.

> **Quem é o DONO do conceito?** `CustomerInfo` descreve o cliente de um
> orçamento → módulo `budget` é o dono. Os outros importam de `budget`. Se
> houver
> dependência circular, crie `core/customer/` ou use interface no domain do
> consumidor.

### 10.4 Diretriz para o Agente (Ponytail)

> **Quando o usuário pedir para criar um model, entity, DTO ou classe de dados,
o agente DEVE perguntar: "Qual é o módulo dono?" e colocar o arquivo em
`modules/{modulo}/data/model/` ou `modules/{modulo}/domain/entity/` — NUNCA em
`shared/models/`.**
>
> Se o agente não souber o módulo, ele deve **perguntar ao usuário antes de
criar o arquivo**. Criar em `shared/models/` é FALHA de arquitetura.

---

## 11. Plano de Migração — Models de `shared/models/` para Módulos

> **Instrução ponytail: migrar um módulo por vez. NUNCA o projeto todo.**

### Inventário atual

| Arquivo                    | Módulo Dono                | Justificativa                                                                                        |
|----------------------------|----------------------------|------------------------------------------------------------------------------------------------------|
| `address.dart`             | `core/cep`                 | Retorno da API ViaCep                                                                                |
| `customer_info.dart`       | `budget`                   | Cliente do orçamento — usado por `budget`, `pdf`, `payment`, `web_budget`, `product` como dependente |
| `global_uid_budget.dart`   | `shared/common/constants/` | Não é model de negócio; é constante de path do Firestore                                             |
| `global_uid_user.dart`     | `shared/common/constants/` | Idem — constante de path do Firestore                                                                |
| `info_user.dart`           | `login`                    | Dados do usuário logado — usado em `login` e `singup`                                                |
| `items_budget.dart`        | `budget`                   | Item de orçamento — usado por `budget`, `product`, `chat_budget`, `pdf`                              |
| `items_list_budget.dart`   | `budget`                   | Extensão/variante de itens de orçamento                                                              |
| `month_calculate.dart`     | `dashboard`                | Cálculo de evolução mensal — usado só em `dashboard`                                                 |
| `my_budget_dashboard.dart` | `dashboard`                | Resumo de orçamentos para dashboard                                                                  |
| `observation_budget.dart`  | `budget`                   | Observação do orçamento — usada em `budget` e `comment` (comment consome)                            |
| `observation_pdf.dart`     | `budget`                   | Observação para PDF — deriva do conceito de budget                                                   |
| `owner_info.dart`          | **DELETAR**                | Não é importado por ninguém                                                                          |
| `owner_pdf.dart`           | `login`                    | Dados do titular/empresa — usado em `login`, `singup`, `pdf`, `image`                                |
| `payment_customer.dart`    | `payment`                  | Pagamento do cliente — usado em `payment`, `pdf`, `receipt` (receipt consome)                        |
| `receipt.dart`             | `receipt`                  | Recibo — usado em `receipt`, `payment`, `pdf` (os outros consomem)                                   |
| `recent_file.dart`         | **DELETAR**                | Não é importado por ninguém                                                                          |

### Ordem de migração sugerida (do mais isolado para o mais acoplado)

1. **`dashboard`** — `month_calculate.dart`, `my_budget_dashboard.dart`
   (isolados, zero impacto externo)
2. **`core/cep`** — `address.dart` (isolado)
3. **`login`** — `info_user.dart`, `owner_pdf.dart` (acoplado a `singup`, `pdf`,
   `image`)
4. **`receipt`** — `receipt.dart` (acoplado a `payment`, `pdf`)
5. **`payment`** — `payment_customer.dart` (acoplado a `pdf`, `receipt`)
6. **`budget`** — `customer_info.dart`, `items_budget.dart`,
   `items_list_budget.dart`, `observation_budget.dart`, `observation_pdf.dart`
   (acoplado a quase todo mundo — **por último**)
7. **Limpeza** — mover `global_uid_*.dart` para `shared/common/constants/`,
   deletar `owner_info.dart` e `recent_file.dart`

### Checklist por módulo (aplicar a cada migração)

- [ ] Mover o arquivo de `shared/models/` para a pasta correta no módulo
  (`data/model/` ou `domain/entity/`)
- [ ] Atualizar o `import` interno do próprio módulo
- [ ] Atualizar os `import` de **todos** os arquivos que consumiam de
  `shared/models/` para apontar para o novo caminho
- [ ] Se o arquivo era importado por módulos que NÃO são o dono, **anotar a
  dependência cruzada** (futura refatoração de desacoplamento via
  UseCase/Repository)
- [ ] Rodar `flutter analyze` para validar imports quebrados
- [ ] Rodar build/run para validar funcionamento
- [ ] Remover o arquivo antigo de `shared/models/` **só depois** de confirmar
  que nada mais referencia

---

## 12. Dicas Rápidas

### Adicionar um novo campo no formulário

1. Atualizar o modelo no **módulo dono** (`modules/{modulo}/data/model/` ou
   `domain/entity/`)
2. Atualizar o DataSource para persistir o novo campo
3. Atualizar o ViewModel (validação/lógica)
4. Atualizar a View (novo widget de input)
5. Atualizar o componente de PDF se necessário

### Criar um modal de ações

> Antes, classifique o modal (§19): se for **complexo**, ele é uma **tela**
> (pasta própria com View + ViewModel + `components/`). Os passos abaixo valem
> só para modal **simples**.

1. Criar em `presenter/components/modals/{nome}_bottom_modal_widget.dart`
2. Usar `showModalBottomSheet` na View
3. O callback de ação chama um método no ViewModel

### Expor uma nova rota

1. Adicionar no enum `BudgetRoute` (ou módulo correspondente)
2. Adicionar no `Map<String, WidgetBuilder>` do módulo
3. Registrar no `app_routes.dart`
4. Navegar com `Navigator.pushNamed(context, BudgetRoute.budgetCreator.path)`

### Criar um novo UseCase

1. Criar classe em
   `modules/{modulo}/domain/usecase/{acao}_{feature}_usecase.dart`
2. Receber dependências no construtor (repositórios ou outros usecases)
3. Implementar o método principal com a lógica de negócio
4. Retornar `Result<T, E>` quando houver fluxo de erro
5. Registrar no `{modulo}_binds.dart`
6. Injetar no ViewModel via `getIt<MeuUseCase>()`

### Criar strings de um módulo

1. Criar pasta `presenter/strings/` dentro do módulo
2. Criar arquivo `{modulo}_pt_string.dart`
3. Criar classe `static` com getters `static String get ...` (igual ao padrão de
   internacionalização)
4. Mover **todas** as strings literais das Views, ViewModels e componentes do
   módulo para esse arquivo
5. Importar no View, ViewModel e componentes usando
   `import 'package:oflite/modules/{modulo}/presenter/strings/{modulo}_pt_string.dart'`
6. **Nunca colocar strings literais (hardcoded) diretamente em Views, ViewModels
   ou componentes.**

> **Módulo com várias telas** (ex.: `chat_assistant`): cada pasta de tela tem
> o seu `strings/{tela}_pt_string.dart` ao lado da View/ViewModel/`components/`.
> String usada por mais de uma tela fica na tela dona do contexto.

> **IMPORTANTE**: strings usadas por mais de um módulo (ex: `errorTitle`) ficam
> no módulo dono do contexto. Se todos os módulos precisam, use o módulo mais
> baixo na hierarquia (ex: login → signup usa o `errorTitle` do login). Evite
> `shared/common/strings/` — strings são **próprias de cada módulo**.

### Criar um módulo core com datasource

1. Criar `data/datasource/{service}_remote_datasource.dart`
2. Mover todo acesso ao SDK externo (Firebase, HTTP, plugin) para o DataSource
3. Manter o RepositoryImpl como orquestrador (estado, callbacks, regras)
4. Registrar DataSource antes do Repository no `{service}_binds.dart`
5. Injetar DataSource no RepositoryImpl via construtor

---

## 13. Regra de Exibição de Anúncios — Apenas para Não-Assinantes

> **Esta é uma regra arquitetural transversal**: todo anúncio (banner ou
> intersticial) deve ser suprimido automaticamente quando o usuário for
> assinante (premium). A decisão de exibir ou não **não pode ser repetida**
> em cada View/ViewModel.

### 13.1 Princípio — Centralize a Decisão no `core/ads`

As Views declaram **onde** o anúncio apareceria (ex:
`bottomNavigationBar: BannerAdWidget()`), mas **nunca decidem** se ele será
renderizado. Essa decisão pertence exclusivamente ao módulo `core/ads`, que
consulta o estado global de assinatura (`UserRepository`) e decide por conta
própria.

| ❌ NÃO faça                                         | ✅ Faça em vez disso                                      |
|-----------------------------------------------------|-----------------------------------------------------------|
| Verificar `AutoRenewing` em cada View para esconder banner | Injetar `UserRepository` no `AdsRepositoryImpl` e expor `shouldShowAds` |
| Verificar `AutoRenewing` antes de chamar `loadInterstitial()` na View | `loadInterstitial()` já aborta internamente quando `shouldShowAds == false` |
| Duplicar lógica de "premium = sem anúncio" em PDF, Budget, etc. | Usar `BannerAdWidget` e `AdsRepository` sem condicionais externos |

### 13.2 Implementação Padrão

**Contrato (`AdsRepository`)**:
```dart
abstract class AdsRepository {
  /// ... métodos existentes ...

  /// Retorna `true` apenas quando o usuário NÃO é assinante.
  bool get shouldShowAds;
}
```

**Implementação (`AdsRepositoryImpl`)**:
```dart
class AdsRepositoryImpl implements AdsRepository {
  final AdsRemoteDataSource _dataSource;
  final UserRepository _userRepository;

  AdsRepositoryImpl(this._dataSource, this._userRepository);

  @override
  bool get shouldShowAds =>
      !(_userRepository.selectUser.value?.AutoRenewing ?? false);

  @override
  void loadInterstitial() {
    if (!shouldShowAds) return;
    // ... carrega intersticial normalmente
  }

  @override
  void showInterstitial() {
    if (!shouldShowAds) {
      debugPrint('[AdsRepository] Premium — intersticial suprimido.');
      return;
    }
    // ... exibe intersticial normalmente
  }
}
```

**Widget de Banner (`BannerAdWidget`)**:
```dart
class _BannerAdWidgetState extends State<BannerAdWidget> {
  // ...
  @override
  void initState() {
    super.initState();
    // Se o usuário é premium, nem inicia o carregamento.
    if (!getIt<AdsRepository>().shouldShowAds) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }
}
```

> **Dica**: se `AutoRenewing` for atualizado durante o ciclo de vida do app
> (ex: após restore de compra), certifique-se de que o
> `UserRepository.selectUser` notifique listeners. Dessa forma, qualquer
> tela recarregada já refletirá `shouldShowAds == false`.

### 13.3 Quando a View PODE Ainda Verificar `AutoRenewing`

A única exceção legítima é quando a **própria experiência de UI muda** — por
exemplo, um botão de "Compartilhar" que, para não-assinantes, abre uma
opção "Assista anúncio ou vire Premium". Nesse caso:

1. A View/ViewModel **pode** checar `AutoRenewing` para decidir **qual fluxo
   de UI** apresentar.
2. Mas o **disparo do anúncio em si** (`showInterstitial`, ` loadInterstitial`)
   deve ser feito sem condicionais extras — o `AdsRepository` já impede a
   exibição para premium.

### 13.4 Checklist para Novos Módulos com Anúncios

- [ ] O banner é adicionado via `BannerAdWidget()`, sem `if` na View.
- [ ] O intersticial é disparado via `getIt<AdsRepository>().showInterstitial()`,
      sem `if` externo.
- [ ] `AdsRepositoryImpl` recebe `UserRepository` via construtor e expõe
      `shouldShowAds`.
- [ ] `ads_binds.dart` registra `UserRepository` como dependência do
      `AdsRepositoryImpl`.

---

## 14. Regra do `ProductPriceCreator` — Sempre Vincular ao Orçamento quando
      Apropriado

> **Contexto**: o `ProductPriceCreatorView` (`showProductPriceCreatorBottomModal`)
> é usado em dois contextos diferentes: (a) gerenciamento global de produtos
> (lista de preço) e (b) adição de itens dentro de um orçamento.
>
> Quando chamado a partir de uma **tela de orçamento** (`BudgetListItemsView`
> ou `ProductPriceListView` vinculada a um orçamento), o produto criado deve
> ser salvo **tanto na lista de preço (`ProductPriceRepository`) quanto no
> orçamento (`BudgetRepository`)**. Isso é controlado pela flag `fromListItem`.

### 14.1 Implementação

O `ProductPriceCreatorViewModel` recebe `fromListItem` via construtor:

```dart
ProductPriceCreatorViewModel({
  required this.item,
  this.fromListItem = false,
})
```

Quando `fromListItem == true`, o método `_create()` adiciona o produto recém-
criado ao orçamento ativo via `BudgetRepository.saveBudgetItem`:

```dart
Future<String?> _create({required ProductPriceModel model}) async {
  final result = await _productRepository.addProduct(model);
  if (result is Error<String?>) throw result.error;

  if (fromListItem) {
    final id = (result as Ok<String?>).value;
    final budgetItem = ItemsBudget(
      id: id,
      CATEGORIA: model.categoria,
      DESCRICAO: model.descricao,
      PRECO: model.preco,
      QTD: model.qtd,
      MEDIDA: model.medida,
      TOTAL: model.total,
      IDPRODUCT: id,
    );
    await _budgetRepository.saveBudgetItem(
        _budgetRepository.selectBudget.value?.id ?? '', budgetItem);
  }
  // ...
}
```

### 14.2 Quem deve passar `fromListItem: true`?

| Origem da chamada | `fromListItem` | Motivo |
|-------------------|----------------|--------|
| `BudgetListItemsView` (botão "Criar novo item") | ✅ `true` | Está dentro do fluxo de um orçamento |
| `ProductPriceListView` vinculada a orçamento (`fromMenu: false`) | ✅ `true` | Está dentro do fluxo de um orçamento |
| `ProductPriceListView` via menu principal (`fromMenu: true`) | ❌ `false` | Gestão de produtos, não vinculada a orçamento |
| Chat assistant (botão "Criar produto" no menu) | ❌ `false` | O chat reconduz o usuário para selecionar da lista depois |

> **ATENÇÃO**: `ProductPriceCreatorViewModel` usa
> `_budgetRepository.selectBudget.value?.id` para descobrir o id do orçamento.
> Quem abre o creator obrigatoriamente deve ter garantido que
> `BudgetRepository.selectBudget.value` está populado com o orçamento correto.

### 14.3 Checklist para Evitar Regressão

- [ ] `BudgetListItemsView` seta `selectBudget.value = widget.item` antes de
      abrir qualquer tela/modal que possa salvar itens.
- [ ] `BudgetListItemsView._showProductPriceCreatorBottomModal()` passa
      `fromListItem: true`.
- [ ] `ProductPriceListViewModel.openCreator()` calcula
      `fromListItem: this.item != null && !fromMenu`.
- [ ] `ProductPriceListViewModel.addNew()` não precisa de mudança (delega para
      `openCreator()`).

---

## 15. Regra de Cores — Fonte Única em `colors.dart`

Toda cor usada no app **deve** estar declarada em
`lib/shared/common/constants/colors.dart` e ser usada **a partir desse
arquivo**. Isso vale também para as cores do Material (`Colors.red`,
`Colors.grey.shade300`, `Colors.transparent` etc.).

**Por quê?** Numa migração de paleta ou na implementação de dark mode, basta
alterar um único arquivo — em vez de caçar `Color(0x...)` e `Colors.*`
espalhados pelas Views e componentes.

### 15.1 Regras

- **NUNCA** use `Color(0xFF...)` ou `Colors.*` diretamente em View, componente,
  modal ou tema. Importe a constante de `colors.dart`.
- Se a cor **não existir** em `colors.dart`, **adicione-a lá** antes de usar.
- Antes de criar, verifique se já existe uma constante com o mesmo valor —
  reaproveite em vez de duplicar.
- **Nomenclatura**: o nome deve remeter ao **uso** da cor (preferível —
  ex: `errorColor`, `cardBackgroundColor`, `dividerColor`) ou ao **nome da cor**
  propriamente dita (ex: `slateGray`, `snowColor`, `greyLight`).
- Cores do Material entram como alias:
  `const dividerColor = Colors.grey;` / `const transparentColor = Colors.transparent;`.

### 15.2 Exemplo

```dart
// ❌ NÃO fazer
Container(color: Colors.grey.shade300);
Text('Erro', style: TextStyle(color: Color(0xFFB71C1C)));

// ✅ colors.dart
const greyLightColor = Color(0xFFE0E0E0); // Colors.grey.shade300
const redColor = Color(0xFFB71C1C);

// ✅ No widget
Container(color: greyLightColor);
Text('Erro', style: TextStyle(color: redColor));
```

> **Diretriz para o Agente**: ao tocar em um arquivo que usa cor hardcoded,
> mova a cor para `colors.dart` e substitua o uso pela constante.

---

## 16. Flutter Web — Como Funciona e Como Criar uma Nova Tela Web

O projeto tem **dois entrypoints**. O Web **não** é o app mobile rodando no
navegador: ele publica **apenas** telas específicas e públicas.

| Entrypoint          | Plataforma     | O que publica                                                        |
|---------------------|----------------|----------------------------------------------------------------------|
| `lib/main.dart`     | Android / iOS  | App completo (`appRoutes` de `app_routes.dart`)                      |
| `lib/main_web.dart` | Web            | **Só** o fluxo público de orçamento + `/delete-account` + `/support` + páginas legais (16.8) |

### 16.1 O que existe hoje no Web

| URL pública                                       | Tela                               | Módulo           |
|---------------------------------------------------|------------------------------------|------------------|
| `/orcamento/{enderecoNumero}?token={idToken}`     | `BudgetWebAppView` (home padrão)   | `web_budget`     |
| `/delete-account`                                 | `DeleteAccountView`                | `delete_account` |
| `/support`                                        | `SupportView`                      | `support`        |
| `/termos-de-uso` · `/terms-of-use`                | `LegalView` (EULA pt/en)           | `legal`          |
| `/politica-de-privacidade` · `/privacy-policy`    | `LegalView` (Privacidade pt/en)    | `legal`          |

- **Hosting**: Firebase Hosting, projeto `orcamentofacil-lite`
  (`https://orcamentofacil-lite.web.app`), servindo `build/web`.
- **Firebase Web**: configurado em `_webFirebaseOptions` dentro do próprio
  `main_web.dart` (não mexe no `firebase_options.dart` do mobile).
- **Tema**: `AdaptiveTheme` próprio no `BudgetWebApp` (inicia em dark).

### 16.2 Como o `main_web.dart` escolhe a tela

O Web **não usa** `appRoutes`. O `BudgetWebApp` lê `Uri.base.path` (URL real
do navegador) e decide o `home` pelo helper `_homeFor`:

```dart
return MaterialApp(
  routes: {...deleteAccountRoutes, ...supportRoutes}, // só rotas Web explícitas
  home: _homeFor(Uri.base.path),
);

Widget _homeFor(String path) {
  bool match(String p) => path == p || path.startsWith('$p/');
  if (match(DeleteAccountRoute.deleteAccount.path)) return const DeleteAccountView();
  if (match(SupportRoute.support.path)) return const SupportView();
  return const BudgetWebAppView();
}
```

Qualquer path não reconhecido cai em `BudgetWebAppView`, que bloqueia o acesso
se a URL não tiver `/orcamento/{id}?token=...` válido.

### 16.3 Fluxo do orçamento público (`web_budget`)

```
Mobile (dono)                                      Web (cliente)
─────────────                                      ─────────────
ShareLinkRepositoryImpl.buildShareUrl()
  base = --dart-define BUDGET_WEB_BASE_URL
         (default https://orcamentofacil-lite.web.app)
  → {base}/orcamento/{enderecoNumero}?token={Firebase ID Token do dono}
                                    │
                                    ▼
                         BudgetWebAppViewModel.parseAndValidate(Uri.base)
                           loading → blocked | auth → access
```

| Fase      | Tela                       | Condição                                                    |
|-----------|----------------------------|-------------------------------------------------------------|
| `loading` | spinner                    | validando                                                   |
| `blocked` | `BudgetWebAppBlockedView`  | sem id, sem token, JWT inválido/expirado, 401/403/404       |
| `auth`    | `BudgetWebAuthView`        | token ok → cliente confirma o **telefone** (2ª camada)      |
| `access`  | `BudgetWebBudgetView`      | token + telefone ok → dados, itens, PDF, aprovar/reprovar   |

**Segurança (não negociável):**
1. `enderecoNumero` (document id) **localiza** o orçamento — nunca o telefone.
2. O **token** (Firebase ID Token do dono, ~1h) **autoriza** — o `uid` do dono
   é extraído do JWT para montar o path.
3. O **telefone** é a segunda validação.
4. **Nenhum dado** é exibido antes das três checagens passarem.

**Acesso a dados no Web**: `WebBudgetService` usa a **Firestore REST API**
(`firestore.googleapis.com`) com `Authorization: Bearer {token}`, no mesmo path
do mobile (`EMPRESAS/{uid}/USERS/{uid}/ORCAMENTOS/{id}`). As regras do
Firestore continuam sendo a fonte de verdade. Escritas existentes:
- `updateStatus` → só o campo `STATUS` (mesmos valores do mobile).
- `sendApprovalNotification` → documento em `.../NOTIFICACOES`, que o app do
  dono escuta e transforma em notificação local (best-effort).

**PDF**: reutiliza os `PdfGenerateBudget*Usecase` do módulo `pdf` (mesma
regra do mobile). Download via `budget_web/utils/web_pdf_saver.dart` (import
condicional: `web_pdf_saver_web.dart` com `package:web` no navegador,
`web_pdf_saver_io.dart` como stub no mobile).

### 16.4 Estrutura de pastas do `web_budget`

```
lib/modules/web_budget/
├── web_budget_binds.dart          # registra BudgetWebAppViewModel (factory)
├── web_budget_routes.dart         # enum WebBudgetRoute + webBudgetRoutes
├── services/web_budget_service.dart   # Firestore REST com token do dono
├── strings/budget_web_strings.dart    # textos do fluxo Web
└── budget_web/
    ├── budget_web_app/            # raiz: parse da URL + fases
    ├── budget_web_auth/           # validação do telefone
    ├── budget_web_budget/         # orçamento liberado
    ├── budget_web_pdf_data/       # dados, itens, comentários, PDF, aprovação
    ├── budget_web_items/          # total bar + modal de aprovação
    └── utils/web_pdf_saver*.dart  # download de PDF (import condicional)
```

Cada tela segue o padrão `{tela}_view.dart` + `{tela}_view_model.dart` +
`components/`. ViewModels que recebem parâmetros (`ownerUid`, `token`,
`enderecoNumero`) são instanciados na View via construtor — só os sem
parâmetro vão para o `get_it`.

### 16.5 Passo a passo — Criar uma NOVA tela Web

1. **Decidir onde salvar**
   - Faz parte do fluxo do orçamento público? → subpasta em
     `lib/modules/web_budget/budget_web/{nova_tela}/`.
   - É uma página Web independente (ex.: `delete_account`)? → **módulo
     próprio** em `lib/modules/{modulo}/` com a estrutura padrão
     (`data/`, `domain/`, `presenter/`, `{modulo}_binds.dart`,
     `{modulo}_routes.dart`) — seção 5.
2. **Criar a rota** no `{modulo}_routes.dart` com enum + `path` em
   kebab-case (ex.: `/delete-account`).
3. **Registrar binds** no `injection.dart` (`register{Modulo}Dependencies`) —
   o `main_web.dart` também chama `setupDependencyInjection()`.
4. **Expor no `main_web.dart`**:
   - adicionar o mapa de rotas em `routes: {...}`;
   - adicionar um `if (match(...))` no `_homeFor`. Sem isso a URL cai no
     `BudgetWebAppView` e é bloqueada.
5. **Adicionar rewrite no `firebase.json`** (antes do `"**"`):
   ```json
   { "source": "/nova-tela", "destination": "/index.html" }
   ```
6. **Dados remotos**: o Web **não** tem usuário autenticado do app.
   - Se precisa ler/gravar dados do dono → usar o token da URL via REST
     (padrão `WebBudgetService`), sem criar novo sistema de autenticação.
   - Se chama Cloud Function → datasource com `DioClient` e
     `extra: kIsWeb ? {'withCredentials': false} : null` (padrão
     `DeleteAccountRemoteDataSource`, evita problema de CORS).
   - Valor fixo de configuração (ex.: número de suporte) → constante no
     próprio módulo (padrão `SupportViewModel.whatsappNumber`, ver 16.6).
     O Web não tem token para ler Firestore sem login.
7. **Código só-Web** (`package:web`, `dart:js_interop`): **sempre** atrás de
   import condicional (`export 'x_io.dart' if (dart.library.html) 'x_web.dart';`)
   para não quebrar o build mobile. Nunca importar `dart:html`.
8. **Reutilizar** regras existentes (usecases, models do módulo dono, strings,
   `colors.dart`). Não duplicar regra de negócio para o Web.
9. **Responsividade**: a tela abre em celular e desktop — limitar largura do
   conteúdo (`ConstrainedBox`/`maxWidth`) e testar em telas estreitas.
10. **Testar e publicar**:
    ```bash
    flutter run -d chrome --target lib/main_web.dart
    flutter build web --target lib/main_web.dart
    firebase deploy --only hosting
    ```

### 16.6 Página de suporte (`support`) — Support URL da App Store

`https://orcamentofacil-lite.web.app/support` é a URL cadastrada em
*App Store Connect → App Information → Support URL*. Mostra um botão central
**"Falar com suporte"** que abre o WhatsApp (`https://wa.me/{numero}?text=...`)
via `url_launcher` (`LaunchMode.externalApplication`).

**De onde vem o número**: constante `SupportViewModel.whatsappNumber`
(só dígitos, com DDI + DDD, ex.: `5515997861271`) + `displayNumber` para
exibição. Para trocar: editar a constante e fazer deploy do Web.

> Por que não Firestore? O Web não tem usuário autenticado; ler um documento
> exigiria token ou regra de leitura pública. Para um valor que muda raramente,
> a constante é o menor código (Ponytail).

Sem `data/` nem `domain/` — não há fonte externa (seção 3.4).

```
lib/modules/support/
├── support_binds.dart                 # registerFactory<SupportViewModel>
├── support_routes.dart                # enum SupportRoute { support } → '/support'
└── presenter/
    ├── support_view.dart              # botão central + número selecionável
    ├── support_view_model.dart        # whatsappNumber + openWhatsApp()
    └── strings/support_pt_string.dart
```

O número também aparece como `SelectableText` (fallback para quem não tem
WhatsApp — a Apple exige um contato visível na página).

### 16.7 Regras de Ouro do Web

- **NUNCA** exponha telas do app mobile no Web “de brinde”: só entra o que
  estiver explicitamente no `main_web.dart`.
- **NUNCA** altere o fluxo mobile (`main.dart`, `firebase_options.dart`,
  repos autenticados) para atender o Web — o Web é **aditivo**.
- **NUNCA** mostre dados antes de validar o acesso.
- Use `kIsWeb` só para ajustes pontuais (ex.: `Image.network` vs `Image.file`,
  pular `File`/`path_provider`); diferença grande de comportamento vira
  implementação separada com import condicional.
- Especificações originais detalhadas: `.pi/web_projet_instruction/`
  (`new_project_web.md` e `create_flutter_web_page.md`).

### 16.8 Páginas legais (`legal`) — EULA e Política de Privacidade

URLs cadastradas na App Store / Play Console:

| Documento               | Português                    | English            |
|-------------------------|------------------------------|--------------------|
| Termos de Uso (EULA)    | `/termos-de-uso`             | `/terms-of-use`    |
| Política de Privacidade | `/politica-de-privacidade`   | `/privacy-policy`  |

- O **idioma vem da URL** (não do Locale do navegador) — cada link é estável.
- Uma única `LegalView` recebe um `LegalDocument` (entity do módulo); os
  textos ficam em `presenter/strings/legal_{pt,en}_string.dart`. Para alterar
  um texto: editar a string, atualizar `lastUpdated` e fazer deploy do Web.
- Links entre documentos/idiomas recarregam a URL real
  (`LegalViewModel.open` → `url_launcher` com `_self`), pois o
  `main_web.dart` escolhe a tela pelo path.
- Nova rota legal = novo valor em `LegalRoute` + rewrite no `firebase.json`.

```
lib/modules/legal/
├── legal_binds.dart                   # registerFactory<LegalViewModel>
├── legal_routes.dart                  # enum LegalRoute (path + view) → legalRoutes
├── domain/entity/legal_document.dart  # LegalDocument + LegalSection
└── presenter/
    ├── legal_view.dart
    ├── legal_view_model.dart          # open(path)
    ├── components/legal_body.dart, legal_link_chip.dart
    └── strings/legal_pt_string.dart, legal_en_string.dart
```

---

## 17. UX de Formulários — Regras Obrigatórias

Todo formulário do app (criar/editar orçamento, item, cliente, etc.) segue os
princípios abaixo. Base: Gestalt, Lei de Hick, carga cognitiva e validação
resiliente.

### 17.1 Gestalt
- **Proximidade:** label colado ao seu campo; campos relacionados no mesmo card;
  espaço maior **entre** cards do que **dentro** deles.
- **Continuidade:** uma única coluna vertical, de cima para baixo. Nada de
  campos lado a lado (exceto pares curtos e óbvios, ex.: número/complemento).
- **Fechamento:** cada grupo vive num contêiner (card) com padding e raio
  consistentes; o usuário deve ver onde o formulário começa e termina.

### 17.2 Lei de Hick
- **Menos campos é mais:** peça só o necessário para o objetivo atual; campos
  opcionais ficam agrupados e marcados como "opcional".
- **Poucas opções, visíveis:** até ~5 opções fixas (ex.: status) → chips/segmented
  em vez de dropdown + bottom sheet (um toque em vez de dois).
- **Etapas:** fluxos longos são divididos em passos com indicador de progresso.
  Se já existir navegação por abas (ex.: Cliente/Itens/PDF), ela **é** o stepper —
  não duplicar.

### 17.3 Carga cognitiva
- **Label sempre visível** (floating/fixed label). Placeholder só como exemplo
  de valor, nunca como único rótulo.
- **Máscaras automáticas** para telefone, CEP, CPF, moeda, data.
- **Autopreenchimento** quando houver fonte (CEP → endereço, agenda → contato),
  sempre com feedback visual do que foi preenchido e possibilidade de editar.
- Ações auxiliares (ex.: "Importar da agenda") são **botões explícitos**; nunca
  dispare modal ao focar um campo.

### 17.4 Feedback e validação
- Erro **abaixo do campo afetado**, texto humano ("Informe o nome do cliente"),
  nunca alerta genérico no topo nem exceção crua.
- Validar **on blur** ou no submit — nunca enquanto o usuário digita.
- Erro **preserva** o que já foi digitado.
- Sucesso de save: feedback leve via snackbar padrão do app (§18), sem bloquear a tela.

### 17.5 Modo Criar × Modo Editar
A mesma tela atende criação e atualização; o estado deve ficar óbvio:

| Elemento | Criar | Editar |
|---|---|---|
| Título | "Criar orçamento" | "Editar orçamento" |
| Identificação (nº e data) | oculta (gerada no save) | **card de resumo somente leitura** no topo (nº, data, status) — não aparece como campo de input |
| Campos editáveis | vazios | preenchidos |
| Botão principal | "Continuar" | "Salvar alterações" — só destaca quando há mudanças (dirty) |

- **Campos imutáveis** (nº do orçamento, data de criação) **nunca** são
  `TextField` desabilitado: exibir como texto/badge informativo. Campo cinza
  "desabilitado" confunde e parece erro.
- Após o primeiro save no modo criar, a tela passa ao modo editar sem
  recarregar e já exibe o card de resumo.

### 17.6 Componentes compartilhados
Use os widgets de `shared/common/widgets/form/` em todo formulário:
`AppFormSectionCard` (grupo), `AppFormField` (label visível + erro inline) e
`AppFormSaveButton` (destaque por dirty + loading). Referências:
`budget_creator` e `receipt_creator`.

### 17.7 Layout fixo
- **Não alterar a tab bar / bottom navigation** existente ao redesenhar telas.
- Botão principal flutua sobre o formulário (`Stack` + `Positioned` no
  rodapé), com **fundo sólido** mesmo sem
  alterações (senão some sobre os cards). Reserve padding inferior no scroll
  (~96) para o último campo não ficar sob o botão.

### 17.8 Teclado e foco de campo
- **Campo focado em evidência**: `AppFormField` usa `scrollPadding` de ~30% da
  altura da tela, então ao focar o campo rola para perto do centro da área
  visível. Campos fora do `AppFormField` devem fazer o mesmo.
- **Tela de formulário rola inteira**: o header (`AppHeaderSecondTitle`) é o
  primeiro item do `ListView`, não fica fixo no topo — assim sobra espaço
  para o campo focado aparecer acima do teclado. Envolva o scroll em
  `SafeArea(bottom: false)` para o conteúdo não passar sob a status bar e
  passe `insideSafeArea: true` ao `AppHeaderSecondTitle` (senão o espaço do
  topo dobra).
- **Teclado aberto → botão some**: detecte com
  `View.of(context).viewInsets.bottom > 0` dentro de um `LayoutBuilder`.
  **Não use `MediaQuery.viewInsetsOf`**: as telas ficam dentro da `Scaffold`
  das abas, que já consome o inset, e ele volta sempre 0. Não renderize o
  `AppFormSaveButton`; ele volta quando o teclado
  fecha. Nada pode cobrir o campo em edição.
- **Fechar o teclado é nativo**: não existe mais barra "Fechar teclado" (ocupava
  espaço). O `MaterialApp.builder` (`main.dart`) fecha o teclado em qualquer
  toque fora do campo. Mantenha `keyboardDismissBehavior: onDrag` no scroll e
  `textInputAction: done` no último campo.
- **Telas de formulário não têm banner de anúncio** (`BannerAdWidget`): ele
  rouba espaço do campo em edição.
- Referências: `budget_creator_view.dart` e `receipt_creator_view.dart`.

---

## 18. Feedback ao Usuário — Snackbar Padrão do App

Todo feedback de sucesso, aviso ou erro usa o **snackbar padrão**
(`AlertSnackBar`, em `shared/common/widgets/alert/alert_snack_bar_widget.dart`),
que mantém cores (verde/laranja/vermelho), ícone, título + mensagem e estilo
flutuante consistentes em todo o app.

### 18.1 Como usar
Chame os métodos estáticos do `AlertSnackBar` direto (não existe repository
para alerta: é só UI, sem fonte de dados):

| Situação | Método |
|---|---|
| Sucesso | `AlertSnackBar.success(context, título, mensagem)` |
| Aviso | `AlertSnackBar.warning(context, título, mensagem)` |
| Erro | `AlertSnackBar.error(context, título, mensagem)` |

```dart
AlertSnackBar.success(
  context,
  'Alterações salvas',
  'Dados do orçamento atualizados.',
);
```

> Modais: abra com `showAppModal` e o widget do modal. Modal que executa regra
> (ex.: trocar nome) recebe um `onSave` **sem `BuildContext`** que devolve
> `Result`; o modal só fecha/avisa após checar `mounted`.

### 18.2 Regras
- **NUNCA** use `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))`
  direto em telas/componentes.
- **NUNCA** crie repository/wrapper para alerta ou modal: use `AlertSnackBar`
  e `showAppModal` direto.
- **NUNCA** exiba exceção crua (`${cmd.result}`, `e.toString()`) ao usuário:
  escreva o que aconteceu + o que fazer (§17.4).
- Todo `Command` de save trata **os dois** desfechos: `completed` (sucesso) e
  `error` (falha) — falha silenciosa é bug.
- Verifique `mounted` antes de usar `context` após `await`.
- Para erro de **campo específico**, use erro inline abaixo do campo (§17.4),
  não snackbar.


---

## 19. Modais — Simples × Complexos (Modal-Tela)

> **Regra de Ouro**: modal complexo **é uma tela**. Tem pasta própria, View,
> ViewModel e `components/` — exatamente como qualquer tela de `presenter/`.
> A única diferença é que é aberto com `showModalBottomSheet` em vez de rota.
> Colocar vários widgets, estado e regra dentro de um único arquivo
> `*_bottom_modal_widget.dart` é **inadmissível**.

### 19.1 Como classificar

| O modal… | Tipo | Estrutura |
|---|---|---|
| Só exibe texto/opções e devolve uma escolha (`Sim/Não`, lista de ações, aviso) | **Simples** | 1 arquivo `{feature}_{acao}_bottom_modal_widget.dart`, sem ViewModel |
| Usa **UseCase ou Repository** (salva, busca, atualiza) | **Complexo** | Modal-tela |
| Tem **estado** de formulário (controller, validação, dirty, erro inline, valor calculado ao vivo) | **Complexo** | Modal-tela |
| Precisa de **mais de um widget** próprio para ser montado | **Complexo** | Modal-tela |

> Na dúvida, é complexo. Modal simples **não** chama UseCase nem Repository de
> implementação — se precisar, vira modal-tela.

### 19.2 Estrutura do modal-tela

```
presenter/
└── budget_item_quantity/                       # pasta própria (= tela)
    ├── budget_item_quantity_view.dart          # View + helper show...BottomModal
    ├── budget_item_quantity_view_model.dart    # estado + Command de save
    └── components/                             # 1 widget público por arquivo
        ├── budget_item_quantity_input.dart
        └── budget_item_quantity_read_only_field.dart
```

### 19.3 Regras

| # | Regra |
|---|-------|
| 1 | A **View** é `StatefulWidget`: cria o ViewModel no `initState`, descarta no `dispose`, reconstrói via `AnimatedBuilder`. Usa `AppBottomModal` como base visual. |
| 2 | O **ViewModel** detém estado (controllers, erro inline, dirty, valores calculados) e executa a ação async via **`Command`** (§4.4) chamando o **UseCase/Repository**. |
| 3 | **Nenhuma classe de widget além da View** no arquivo da View, nem `class _Algo` (§2.1). Todo widget auxiliar vai em `components/` do próprio modal, **um por arquivo**, público, recebendo dados + callbacks (nunca o ViewModel inteiro). |
| 4 | O helper `show{Modal}BottomModal(context, …)` fica no arquivo da View e **retorna o resultado** (`bool`/valor) para a tela de origem — ex.: `true` quando salvou. |
| 5 | **Quem salva é o modal.** Em erro, o modal continua aberto (preserva o que foi digitado) e mostra o feedback (§18). Em sucesso, fecha com `pop(true)`. |
| 6 | A **tela de origem** só reage ao retorno (recarregar lista/totais + snackbar de sucesso). Ela **não** recebe o valor cru para salvar por conta própria. |
| 7 | Strings em `presenter/strings/` do módulo; cores de `colors.dart` (§15). |
| 8 | **Altura máxima de 80%** da área visível (tela − teclado), garantida pelo `AppBottomModal` (`maxHeightFactor`). Header (handle + título + fechar) fica fixo e **nunca** vai para baixo da status bar; o conteúdo **rola por dentro**: o `child` é um `SingleChildScrollView`/`ListView`, ou passe `scrollable: true` quando o conteúdo é fixo (Column/Padding). Nunca abrir modal em tela cheia sem SafeArea. |

### 19.4 Referências no projeto

- **Modal-tela**: `budget/presenter/budget_item_quantity/` (detalhes do item +
  edição de quantidade), `product/presenter/product_price_creator/`.
- **Modal simples**: `shared/common/widgets/modals/confirm_bottom_modal_widget.dart`.

---

## 20. Assistente com IA (Gemini via Firebase AI Logic)

O chat do assistente (`modules/chat_assistant`) tem dois modos:

| Modo | Quem | Como responde |
|------|------|---------------|
| **Padrão (determinístico)** | Usuário free — e qualquer usuário quando a IA falha (§20.8) | State machine (`ChatFlowStep`) + menus de botões. **Nunca muda por causa da IA.** |
| **IA** | Assinante (`autoRenewing`) ou `FORCE_PREMIUM` em development | Texto livre no menu principal vai para o Gemini, que **opera o app chamando tools** (function calling) que executam os **mesmos UseCases das telas**. |

> Plano completo e histórico das decisões: `.pi/CHAT_AI_AGENT_PLAN.md`.
>
> **Comprovantes de pagamento pelo chat (Fase 11, em implementação):** botão "+" com
> painel de anexos, recebimento por compartilhamento (Android/iOS), vínculo a
> orçamento e lista `COMPROVANTES` no novo módulo `payment_proof`. Fluxo, regras
> (2 imagens por envio, 15 por orçamento, nome obrigatório) e arquivos em
> `.pi/CHAT_AI_AGENT_PLAN.md` §15.
>
> **Nota fiscal / recibo de compra (planejado):** segundo tipo de anexo, separado
> dos comprovantes de pagamento. Plano completo em **§23** deste arquivo.

### 20.1 Princípios (não negociáveis)

| # | Princípio |
|---|-----------|
| P1 | **LLM decide, UseCase executa.** O modelo só escolhe a tool e os argumentos; a regra de negócio está no UseCase do módulo dono (`budget`, `receipt`…). |
| P2 | **LLM nunca calcula.** Somas, contagens e totais vêm do UseCase, já formatados (`ConvertCoinRepository`). O modelo só repete. |
| P3 | **`firebase_ai` só no DataSource** (`ChatAiRemoteDatasource` e `core/ai_text/AiTextRemoteDatasource` — texto simples, sem tools; limite 30/dia no `GenerateAiTextUsecase`). O domínio declara tools como dados neutros (`AgentToolSpec`) e nunca importa o SDK. |
| P4 | **Toda escrita é confirmada pelo usuário.** A tool de escrita só devolve uma prévia + botões *Confirmar/Cancelar*; quem grava é o `ConfirmAgentActionUsecase`, sem chamar a IA. |
| P5 | **Valor persistido fixo** (Regra Zero do i18n): status trafega como `PENDENTE/APROVADO/REPROVADO/FINALIZADO` (`BudgetStatus`); só o label é traduzido. |
| P6 | **Resposta é UI.** A lista completa vai para um card nativo; ao modelo vai no máximo 20 itens enxutos. |
| P7 | **Free não sente nada.** Sem acesso à IA o chat é idêntico ao de antes. |
| P8 | **Nunca trava.** Timeout + rede de segurança devolvem o usuário ao modo padrão (§20.8). |

### 20.2 Fluxo de um turno

```
ChatAssistantView ── texto livre (step mainMenu, _aiMode) ──► ChatAssistantViewModel
                                                                │ isAiThinking = true  → ChatTypingIndicator
                                                                ▼
RunAgentTurnUsecase  (limite diário → system prompt → loop máx. 5)
   │  ChatAiRepository.send(history, tools)
   │      └─ ChatAiRemoteDatasource ── firebase_ai (timeout 20s) ──► Gemini
   │  modelo pediu tool?
   │      sim → DispatchAgentToolUsecase(call) → UseCases (budget/receipt/share_link)
   │             leitura  → functionResponse enxuto volta ao modelo → repete
   │             escrita  → para: AgentPendingAction + prévia (Confirmar/Cancelar)
   │             start_flow / open_budget → para: handoff / navegação
   │      não → texto final
   ▼
AgentTurnResult { text, messages (cards), pending?, menuOption?, navigation? }
   ▼
ViewModel publica texto + cards; Confirmar → ConfirmAgentActionUsecase (grava, sem IA)
```

- **Teto do turno:** 45 s no ViewModel (cobre Firestore pendurado nas tools).
- **Histórico:** `ChatAiRepository` guarda as últimas 20 mensagens e sempre recomeça
  numa mensagem de texto do usuário (nunca numa tool órfã).
- **Thought signature:** turnos do modelo com tool calls são guardados como as
  *parts* cruas (`Map`) e reenviados com `UnknownPart` — o Gemini exige a
  assinatura original e o domínio continua sem conhecer o SDK.

### 20.3 Tools disponíveis

| Tool | Tipo | Executa | Saída |
|------|------|---------|-------|
| `start_flow` | handoff | `HandleMainMenuOptionUsecase` (opção `1..4`) | Abre o fluxo guiado existente (orçamento, preços, PDF, nome) |
| `list_budgets` | leitura | `ListBudgetsUsecase` (budget) | Card `budgetList` (toque abre o orçamento) |
| `get_month_summary` | leitura | `GetMonthSummaryUsecase` (budget) | Card `summaryCard` (total + por status) |
| `list_receipts` | leitura | `ListReceiptsByBudgetUsecase` (receipt) | Texto (recibos, recebido, saldo) |
| `get_receipts_report` | leitura | `GetReceiptsReportUsecase` (receipt) | Card `receiptsReportCard` (qtd, emitido, recebido, por dia/semana, top orçamentos) |
| `get_budget_link` | leitura | `ShareLinkRepository.buildShareUrl` | Botão *Compartilhar link* (`share_url|<url>`) |
| `open_budget` | navegação | — | Abre `BudgetTabView` (`open_budget|<id>`) |
| `create_receipt` | **escrita** | `CreateReceiptForBudgetUsecase` (receipt) | Prévia + Confirmar/Cancelar |
| `update_budget_status` | **escrita** | `UpdateBudgetStatusUsecase` (budget) | Prévia + Confirmar/Cancelar |

Argumento inválido (data fora de `yyyy-MM-dd`, status inexistente, orçamento não
encontrado, tool desconhecida) **não lança**: vira `{error: ...}` no
`functionResponse` e o modelo se corrige sozinho.

**Adicionar uma tool nova:**
1. Regra de negócio → UseCase no módulo dono (com teste).
2. Declarar em `DispatchAgentToolUsecase.tools` (`AgentToolSpec`; `type`: `enum`/`string`/`number`; `required: true` quando obrigatório).
3. Tratar no `switch` do `call`: leitura devolve `modelPayload` enxuto (+ card); escrita devolve só `pending` + `previewText`.
4. Escrita: executar em `ConfirmAgentActionUsecase`.
5. Se precisar, citar a regra no `aiSystemPrompt` (strings).

### 20.4 Arquivos

```
modules/chat_assistant/
├── data/
│   ├── datasource/chat_ai_remote_datasource.dart   # ÚNICO com firebase_ai (modelo, timeout, tools → Schema)
│   ├── datasource/chat_ai_local_datasource.dart    # contador diário (SharedPreferences)
│   └── repository/chat_ai_repository_impl.dart     # histórico (janela 20), Map ↔ entity, log de tokens
├── domain/
│   ├── entity/agent_message_entity.dart            # user | model (texto ou parts cruas) | tool
│   ├── entity/agent_tool_entity.dart               # AgentToolSpec, chamadas, outcome, turn result, pending, AiDailyLimitException
│   ├── repository/chat_ai_repository.dart
│   └── usecase/
│       ├── check_ai_access_usecase.dart            # assinante || FORCE_PREMIUM; kill switch aiChatEnabled
│       ├── run_agent_turn_usecase.dart             # loop de function calling + limite diário
│       ├── dispatch_agent_tool_usecase.dart        # declara tools, valida args, leituras e prévias
│       ├── confirm_agent_action_usecase.dart       # grava/cancela a escrita confirmada
│       ├── resolve_ai_failure_usecase.dart         # rede de segurança (§20.8)
│       └── show_reports_prompt_usecase.dart        # opção "Relatórios"
└── presenter/chat_assistant/components/
    ├── chat_budget_list_card.dart
    ├── chat_month_summary_card.dart
    ├── chat_receipts_report_card.dart              # relatório de recibos por período
    ├── chat_ai_status_dot.dart
    └── chat_typing_indicator.dart                  # "digitando…" (3 pontinhos)

modules/budget/domain/
├── entity/budget_status.dart  ·  entity/budget_filter.dart
└── usecase/list_budgets_usecase.dart · get_month_summary_usecase.dart · update_budget_status_usecase.dart

modules/receipt/domain/usecase/
├── create_receipt_for_budget_usecase.dart      # recibo + pagamento opcional (invalida o ledger)
├── list_receipts_by_budget_usecase.dart        # recibos + total pago
└── get_receipts_report_usecase.dart            # relatório por período (todos os orçamentos)

modules/receipt/
├── domain/entity/receipt_ledger.dart            # LedgerReceipt{issued, paid} — fonte única de "pago"
├── domain/entity/receipts_report.dart
├── domain/repository/receipt_ledger_repository.dart
└── data/repository/receipt_ledger_repository_impl.dart   # junta recibos+pagamentos; cache 1 min

modules/core/app_check/                          # Firebase App Check (datasource + repo + binds)

modules/payment_proof/                           # Fase 11 — comprovantes (CHAT_AI_AGENT_PLAN §15)
├── data/datasource/payment_proof_remote_datasource.dart   # Firestore ORCAMENTOS/{id}/COMPROVANTES
├── data/datasource/payment_proof_storage_datasource.dart  # Storage comprovantes/{uid}/{budgetId}/
├── data/datasource/proof_file_local_datasource.dart       # compressão (jpg 80, 2048 px) + tamanho
├── domain/usecase/validate_proof_attachments_usecase.dart # 2 imagens OU 1 PDF, 10 MB
├── domain/usecase/check_proof_limit_usecase.dart          # 15 por orçamento
├── domain/usecase/create_payment_proof_usecase.dart       # nome obrigatório, CRIADOEM, rollback
├── domain/usecase/parse_money_input_usecase.dart          # "R$ 500", "1.234,56"
└── presenter/payment_proof_list · payment_proof_viewer    # lista (menu do orçamento) + imagem/PDF

modules/chat_assistant/ (comprovantes)
├── data/datasource/device_media_datasource.dart  # ÚNICO com photo_manager/image_picker/file_selector
├── data/datasource/shared_media_datasource.dart  # ÚNICO com receive_sharing_intent
├── domain/usecase/pick_proof_attachments_usecase.dart · receive_shared_proof_usecase.dart
└── presenter/chat_media_picker (galeria estilo WhatsApp) · chat_proof_preview · components/chat_attachment_panel.dart
```

### 20.5 Regras de domínio relevantes

- **Período de orçamentos:** o ID do orçamento é o timestamp (ms) de criação. O
  período vira range de IDs no Firestore (`fetchBudgetsByMonthRange`), do início
  do dia `from` até **23:59:59.999** do dia `to` (o último dia entra inteiro).
- **Recibo = descrição + pagamentos** (`RECIBOS/{id}/…` pagamentos). O valor
  recebido é um `PaymentCustomer` dentro do recibo — mesmo formato das telas.
- **Estado compartilhado dos repositórios de recibo:** `ReceiptRepository.budgetId`
  e `ReceiptPaymentRepository.budgetId/receiptId` são usados pelas telas. Todo
  UseCase que os altera **restaura o valor anterior no `finally`**.
- **Ledger de recibos (relatórios/saldo):** `ReceiptLedgerRepository` lê TODOS
  os recibos e pagamentos do usuário em 2 consultas `collectionGroup`
  (`RECIBOS`, `PAGAMENTOS`) limitadas ao prefixo `EMPRESAS/{uid}/USERS/{uid}/`
  via `orderBy(documentId)`+`startAt/endAt`. Data do recibo = ID (timestamp ms);
  legado → `DATA`. `issued` = `VALORTOTAL`; `paid` = Σ `PRECO` dos pagamentos.
  **Nenhum outro lugar calcula "pago"** (o saldo do orçamento, Fase 10, usa o
  mesmo ledger). Não toca no `budgetId`/`receiptId` compartilhado. Exige regras
  `match /{path=**}/RECIBOS|PAGAMENTOS/{id}` restritas a `EMPRESAS/{auth.uid}`.
- **Semana:** segunda a domingo; período máximo do relatório: 366 dias.
- **Forma de pagamento:** usa `PaymentStrings.paymentTypeOptions` (o que as telas
  gravam hoje em `METODO`). ⚠️ Débito técnico: é label traduzido persistido.

### 20.6 UX do chat no modo IA

- **Opção "Relatórios"** (5ª do menu, só no modo IA): mostra "Descreva o que você
  precisa saber" + exemplo em destaque; o texto seguinte vai para a IA.
- **Opção "Ir no cliente"** (8ª do menu, só no modo IA, sem LLM): `ShowGoToClientPromptUsecase`
  abre o `ChatBudgetPickerView` → `ShowClientAddressUsecase` mostra "📍 Endereço de …"
  + *Abrir no mapa* (`open_client_map|<id>`), ou aviso de sem endereço + *Selecionar
  outro*. Toda mensagem tem *Voltar ao menu*. O mapa usa o mesmo
  `core/map_launcher` da lista de orçamentos: `ResolveAddressMapsUsecase` (Android:
  seletor nativo; iOS: apps instalados) + `showMapChooserSheet` (action sheet iOS).
  Texto livre ("ir no cliente", "endereço", "abrir no mapa") → IA chama
  `list_budgets` com `purpose: "go_to_client"`, que cai no mesmo fluxo.
- **Digitando…:** `ChatTypingIndicator` no fim da lista enquanto
  `ChatAssistantViewModel.isAiThinking` (modelo pensando ou ação confirmada gravando).
- **Cards:** `budgetList` e `summaryCard` são `ChatMessageType` próprios e ficam
  sempre clicáveis; botão de link (`share_url|`) também.
- **Confirmação:** reaproveita `inlineButtons` com `aiConfirmLabel`/`aiCancelLabel`.
  Nova mensagem digitada descarta a confirmação pendente.
- **Handoff:** `start_flow` entra no fluxo determinístico do menu — fluxos ricos
  em UI (contato, CEP, modal de produto, logo) **não são reescritos para a IA**.

### 20.7 Custo

| Controle | Onde |
|----------|------|
| Modelo `gemini-3.5-flash-lite`, `temperature 0.2`, `maxOutputTokens 512` | `ChatAiRemoteDatasource` |
| Toque em botão/confirmação **nunca** chama a IA | ViewModel / `ConfirmAgentActionUsecase` |
| Máx. 20 itens por `functionResponse`; lista completa só no card | `DispatchAgentToolUsecase` |
| Histórico de 20 mensagens | `ChatAiRepositoryImpl` |
| **100 mensagens/dia por usuário** (`RunAgentTurnUsecase.dailyLimit`) | contador local |
| **30 chamadas/dia** de texto simples (nome + "Melhorar" dos comentários) (`GenerateAiTextUsecase.dailyLimit`) | contador local separado (`core/ai_text`) |
| Log `[AiText] tokens in=… out=…` | `AiTextRepositoryImpl` |
| Log `[ChatAI] tokens in=… out=…` por chamada | `ChatAiRepositoryImpl` |

Faturamento: Gemini Developer API (AI Studio). Usar **recarga automática** com
teto e alerta de orçamento — com créditos zerados toda chamada falha (e o chat
cai no modo padrão).

### 20.8 Rede de segurança (IA falhou → modo padrão)

`ResolveAiFailureUsecase` decide; o ViewModel só conta falhas e aplica:

| Situação | Resultado |
|----------|-----------|
| 1ª falha (erro, timeout, cota, resposta vazia, exceção) | Mensagem `aiFallback`; segue no modo IA |
| `maxConsecutiveFailures` (2) falhas seguidas | Mensagem `aiUnavailable`, `_aiMode = false`, menu reenviado **sem apagar a conversa** (`ResetChatToMenuUsecase(clearSession: false)`) — chat igual ao free |
| Limite diário | Mensagem `aiDailyLimit` + modo padrão já na 1ª vez |
| Resposta boa | Zera o contador |
| Reiniciar conversa (↻) | Reavalia o acesso e volta a tentar a IA |

Timeouts: **20 s** por chamada ao modelo (DataSource) e **45 s** por turno (ViewModel).

### 20.9 Configuração e ambiente

- **Acesso:** `CheckAiAccessUsecase` = `aiChatEnabled && (FORCE_PREMIUM || autoRenewing)`.
- **`FORCE_PREMIUM`** (bool, opcional) só em `env/development_environment.json`.
  `Environment.forcePremium` é sempre `false` em release. Libera **apenas a IA** —
  nunca grava `AutoRenewing` no usuário (o `UserRemoteDataSource` persiste o model).
- **App Check** (`core/app_check`, ativado no `main` só em mobile): release usa
  Play Integrity (Android) / **DeviceCheck** (iOS — não exige entitlement nem
  novo provisioning profile; App Attest exigiria ambos); debug usa o provider de
  debug.
  - **Android:** token fixo via `--dart-define-from-file=env/app_check_debug.json`
    (arquivo no `.gitignore`, chave `APP_CHECK_DEBUG_TOKEN`).
  - **iOS (simulador):** o SDK ignora o token do `dart-define` e usa um token
    local por instalação. Pegue-o no log nativo e cadastre no Console:
    `xcrun simctl spawn booted log show --last 30m --style compact --predicate 'eventMessage CONTAINS "Firebase App Check debug token"' | grep -o "token: .*" | tail -1`
  - Tokens de debug: Console → App Check → Apps → ⋮ → Gerenciar tokens de depuração.
- **Android Studio:** em *Additional run args* da config `development`:
  `--dart-define-from-file=env/development_environment.json --dart-define-from-file=env/app_check_debug.json`.

### 20.10 Testes

| Arquivo | Cobre |
|---------|-------|
| `test/modules/chat_assistant/run_agent_turn_usecase_test.dart` | acesso, loop texto/tool/escrita/handoff, limite diário, corte de loop, parts cruas |
| `test/modules/chat_assistant/dispatch_agent_tool_usecase_test.dart` | payload enxuto × card completo, validação de args, prévias, `ConfirmAgentActionUsecase` |
| `test/modules/chat_assistant/resolve_ai_failure_usecase_test.dart` | rede de segurança |
| `test/modules/chat_assistant/reports_menu_usecase_test.dart` | opção Relatórios e menu com/sem ela |
| `test/modules/budget/domain/usecase/list_budgets_and_summary_usecase_test.dart` | período, acento, agregação, status |
| `test/modules/receipt/create_receipt_for_budget_usecase_test.dart` | recibo + pagamento + restauração de estado |

Pendente: suíte de avaliação contra o modelo real (frases → tool + args esperados),
a rodar a cada troca de modelo/prompt.

---

> **Documento mantido na pasta `.pi/`** — atualizar sempre que novos padrões
> forem adotados.

---

## 21. Single Source of Truth (SSoT) — Fonte Única da Verdade

**Princípio:** cada dado (orçamento, mensagem do chat, comprovante, usuário,
configuração do PDF…) é armazenado, editado e mantido em **um único lugar
autoritativo**. Todo o resto do app **lê desse lugar** — nunca de cópias
soltas, caches locais na tela ou chamadas paralelas à mesma fonte.

> SSoT ≠ DRY: DRY evita repetir **código**; SSoT evita **dados** duplicados
> ou conflitantes. Também não significa "um banco só": significa **dono
> claro** de cada dado e sincronização feita por esse dono.

### 21.1 Quem é o dono no OFLite

| Camada | Papel no SSoT |
|---|---|
| `DataSource` | Única porta para a fonte externa (Firestore, Storage, Auth, HTTP/Dio, `firebase_ai`, banco local). |
| `Repository` | **Dono do dado** no app. Guarda o estado atual (`ChangeNotifier`/`ValueNotifier`), decide cache × remoto e sincroniza. |
| `UseCase` | Regra de negócio sobre os dados do(s) repositório(s). Não guarda cópia. |
| `ViewModel` | Estado **de tela** (step, campos do formulário, loading). Dado de domínio vem do repositório. |
| `View` | Só exibe o que a ViewModel expõe. |

### 21.2 Regras

1. **Nada de HTTP/Firebase fora do DataSource** — nem na View, nem na
   ViewModel, nem no UseCase (complementa a seção 3 e as regras 19/20).
2. **View não chama `getIt<…Repository>()`** — passa pela ViewModel
   (command ou método).
3. **ViewModel não copia dado de domínio para "segurar" na tela** quando o
   repositório já expõe esse dado; escuta o repositório e lê dele.
4. **Uma escrita, um caminho:** toda alteração de um dado passa pelo mesmo
   repositório; quem escreve por fora cria duas verdades.
5. **Sincronização é do repositório** (ex.: local ↔ Firestore). A tela
   nunca decide de onde o dado vem.
6. Ao revisar código, perguntar: *"se esse valor mudar, existe outro lugar
   que vai ficar desatualizado?"* Se sim, viola SSoT.

Referência: <https://en.wikipedia.org/wiki/Single_source_of_truth>


---

## 22. Design System e Responsividade (Tablet/Web)

> Visual: **[`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md)** · Plano de execução e
> checklist de todas as telas: **[`TABLET_RESPONSIVE_PLAN.md`](TABLET_RESPONSIVE_PLAN.md)**.

### 22.1 Regras

1. **Todo detalhe visual** (cor, fonte, raio, espaçamento, componente) vem do
   `DESIGN_SYSTEM.md`. Valor novo entra **primeiro** no documento (e em
   `colors.dart`, §15) e só depois na tela.
2. **Layout decide por largura da janela** (`ResponsiveWidget.sizeOf` /
   `LayoutBuilder`): `compact` < 600, `medium` 600–1023, `expanded` ≥ 1024.
   **Nunca** por `Platform.isIOS/isAndroid` nem `dart:io` em widget de layout
   (o mesmo widget precisa servir ao Web).
3. **Proibido tamanho por fração da tela** (`MediaQuery…size.height * 0.08`,
   `screenAwareSize`) e margens mágicas (`right: 285`). Use a escala de
   espaçamento do design system e `AppPageContainer`.
4. **Tela larga = composição nova em `components/`**; o layout `compact`
   (celular) permanece como está. Widgets adaptativos compartilhados ficam em
   `shared/common/widgets/adaptive/` (§2.1: públicos, um por arquivo).
5. **Tablet abre deitado** (iPad e Android com `shortestSide >= 600`);
   celular não é afetado.
6. **Bottom navigation (§17.7)** continua intacta em `compact`/`medium`;
   em `expanded` a navegação é a sidebar do `main_tab`.
7. **Modais** abrem por `showAppModal` (sheet centralizado, largura máx. 640);
   regras do §19 seguem valendo.
8. Toda **nova tela** entra na matriz do `TABLET_RESPONSIVE_PLAN.md` (§5) com
   seu comportamento em `expanded` antes de ser dada como pronta.

---

## 23. Notas fiscais / recibos de compra (plano) — ao lado dos comprovantes

> **Status:** código Flutter implementado (2026-11-24). **Pendente:** publicar
> regras do Firestore (`NOTASFISCAIS`) e do Storage (`notasfiscais/{uid}/…`) e
> testar em aparelho real.
> Só assinantes (mesmo gate de §20/§15 do `CHAT_AI_AGENT_PLAN`).

### 23.1 Conceito

Dois anexos do orçamento, **mesmo conceito, listas separadas**:

| | Comprovante de pagamento (hoje) | Nota fiscal / recibo de compra (novo) |
|---|---|---|
| O que é | Cliente pagou algo ao prestador | Prestador **comprou** algo para o serviço (ex.: saco de parafusos) |
| Efeito financeiro | Abate o que o cliente já pagou | **Valor de cobrança**: o cliente paga depois |
| Total do orçamento | Não entra | **Não entra** — fica à parte, somado só na lista de notas |
| Coleção | `ORCAMENTOS/{id}/COMPROVANTES` (já existe) | `ORCAMENTOS/{id}/NOTASFISCAIS` (nova, sem migração) |

**Módulo próprio `modules/invoice/`** (data/domain/presenter/binds). Reaproveita de
`payment_proof` só o que é genérico: `ProofAttachment`, `PaymentProofType/Origin`,
`PaymentProofLimits`, compressão de imagem e os componentes de card/detalhe da lista.

### 23.2 Dados e regras

- `Invoice` grava `NOME`, `VALOR` (> 0), `TIPO` (`IMAGEM`/`PDF` — valor fixo,
  Regra Zero do i18n), `ARQUIVO`, `CAMINHO`, `TAMANHO`, `CRIADOEM`, `ORIGEM`.
  Sem CPF/CNPJ (o CPF/CNPJ do Editar PDF era só o exemplo de campo com máscara).
- Limite: 15 notas por orçamento, à parte dos comprovantes.
- Regra de negócio = UseCase: `CreateInvoiceUsecase`, `ListInvoicesUsecase`
  (soma = total a cobrar), `DeleteInvoiceUsecase`, `CheckInvoiceLimitUsecase`.
  Firestore/Storage só nos datasources do módulo.

### 23.3 Fluxo no chat (botão "+")

Inalterado até escolher o orçamento: "+" → painel → até 2 imagens → modal de
orçamentos → texto com botão para reabrir o modal se o usuário fechar
(`proofSelectBudget`). **Não mexer nisso.** A mudança começa depois:

```
[orçamento escolhido]
Bot: "Você quer salvar um comprovante de pagamentos ou uma nota fiscal ao orçamento?"
     [Comprovantes]  [Nota fiscal]  + Voltar ao menu (R10)

[Comprovantes] → fluxo atual (muda só o item 23.5: campo de valor com máscara)

[Nota fiscal]
Bot: "Qual o nome da nota fiscal?"      (Voltar ao menu)
Usuário digita o nome
Bot: "Qual o valor?"
Usuário digita o valor (máscara de moeda)
Formulário na barra inferior (mesmo visual do `ChatDocumentForm`, Editar PDF):
  [ Nome ] [ Valor — máscara moeda ]
  [ Voltar ] [ Salvar ]
Salvar → grava em NOTASFISCAIS → mensagem de sucesso (23.6)
```

- Novo `ChatFlowStep`: só `proofAskKind`; nome/valor/salvando/erro/sucesso
  reaproveitam os `proof*` com `_proofKind` na VM. O limite (15) é conferido
  **depois** da escolha do tipo.
- No passo de valor (`proofAskValue`) a barra de texto dá lugar ao formulário
  (`showProofForm`): comprovante = só valor (máscara de moeda); nota fiscal =
  nome (já preenchido, editável) + valor + Salvar/Voltar.
- Legenda enviada com o arquivo continua preenchendo nome/valor (não repergunta).
- Passos de nome/valor já respondidos viram campos preenchidos do formulário; o
  usuário pode editá-los antes de salvar.
- Toda mensagem do bot tem "Voltar ao menu" e descarta o rascunho (R10). Sem LLM (R8).
- Form = **componente novo** `chat_invoice_form.dart` em `components/` (§2.1),
  reaproveitando o layout do `chat_document_form.dart`; máscaras via
  `mask_text_input_formatter` (já usado na VM do chat) e moeda pelo mesmo
  formatter dos campos de valor do app. Sem lógica na View: validação no usecase.

### 23.4 Menu do orçamento — acesso "Notas fiscais"

Em `budget_options_view_model.dart` novo `BudgetOptionType.invoices`, **idêntico**
ao `proofs` (mesmo gate de assinante, mesmo ícone/estilo, mesma navegação):

- Nova tela `payment_proof/presenter/invoice_list/` (View + VM + `components/`):
  lista de notas igual à de comprovantes (tile, detalhe, visualizador de
  imagem/PDF reaproveitado), com `PaymentProofTotalBar` mostrando **valor total
  das notas** (rótulo "Total a cobrar do cliente") abaixo da lista.
- **Campo para digitar o valor com máscara** de moeda no formulário de
  criação/edição da nota.
- O total das notas **não soma** no total do orçamento nem no ledger de
  recibos; é exibido à parte (e em `budget_metrics`, linha própria, opcional).

### 23.5 Comprovantes — valor com máscara (ajuste no fluxo existente)

Hoje o valor do comprovante é digitado no campo de mensagem do chat
(`proofAskValue` → `ParseMoneyInputUsecase`). Passa a usar **campo de valor com
máscara de moeda** (mesmo form/componente do item 23.3, só com nome + valor),
em vez de texto livre na barra de mensagens. `ParseMoneyInputUsecase.caption`
segue para a legenda do arquivo.

### 23.6 Pós-gravação (comprovante e nota)

Idêntico ao de hoje para comprovante, agora também para nota:

- Emoji/mensagem de sucesso (`PaymentProofStrings.saved` → par `invoiceSaved`).
- Botão para **abrir direto no orçamento** (`open_proofs|{budgetId}`; novo
  `open_invoices|{budgetId}`) levando à lista correspondente.
- `Voltar ao menu`.

### 23.7 Arquivos

```
modules/invoice/
├── invoice_binds.dart
├── data/model/invoice.dart                      # + toProof() p/ reaproveitar card/detalhe
├── data/datasource/invoice_remote_datasource.dart    # NOTASFISCAIS
├── data/datasource/invoice_storage_datasource.dart   # notasfiscais/{uid}/{budgetId}/
├── data/repository/invoice_repository_impl.dart
├── domain/repository/invoice_repository.dart
├── domain/usecase/ create · list · delete · check_limit
└── presenter/invoice_list/ (view + view_model) · presenter/strings/invoice_pt_string.dart

modules/chat_assistant/  # proofAskKind + components/chat_proof_form.dart
modules/budget/          # BudgetOptionType.invoices
```

### 23.8 Checklist de entrega

1. Módulo `invoice` (model, datasources, repositório, usecases, binds).
2. Regras do Firestore/Storage para `NOTASFISCAIS` e caminho `notas/{uid}/{budgetId}/`.
3. Chat: pergunta "comprovante ou nota fiscal?" após escolher o orçamento.
4. Chat: fluxo da nota (nome → valor → formulário nome + valor + Salvar).
5. Comprovante: valor com máscara.
6. Menu do orçamento: acesso Notas fiscais + lista + total + valor com máscara.
7. Sucesso + atalho ao orçamento nos dois fluxos.
8. Strings pt/en (§12), cores só de `colors.dart` (§15), testes dos usecases.
9. Atualizar §20.4/§9 e `CHAT_AI_AGENT_PLAN.md` §15 ao concluir.

### 23.9 Decisões em aberto

- Decidido: sem CPF/CNPJ; nome perguntado por texto e depois editável no
  formulário (o valor só no formulário).
- Total das notas aparece no PDF/link público do orçamento? (fora deste plano)

