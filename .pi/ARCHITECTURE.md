# Padrão de Arquitetura — ESP32 POC / Quem Está Por Aqui

> Documento de arquitetura preciso para criação e refatoração de módulos **sem alterar código existente**. Siga rigorosamente cada regra.

---

## 1. Visão Geral da Arquitetura

O projeto usa **MVVM + Clean Architecture simplificada** com as seguintes camadas:

```
lib/
├── main.dart                 # Entry-point Firebase + DI + app launch
├── app_routes.dart           # Enum central de rotas + mapa de rotas agregado
├── injection.dart            # Registro central de todas as dependências (get_it)
├── modules/
│   ├── core/                 # Módulos transversais (auth, calendar, api, etc.)
│   │   └── <modulo>/
│   │       ├── data/
│   │       │   ├── model/    # Modelos JSON/Freezed (só dados brutos)
│   │       │   └── service/  # Serviços externos (Firebase, Dio, SQLite, etc.)
│   │       └── domain/
│   │           ├── entity/   # Entidades de negócio puras
│   │           └── repository/
│   │               ├── <nome>_repository.dart       # Contrato abstract
│   │               └── <nome>_repository_impl.dart  # Implementação
│   └── <feature>/            # Módulos de tela (presenter + widgets)
│       ├── <feature>_routes.dart
│       ├── presenter/
│       │   ├── <feature>_view.dart
│       │   ├── <feature>_viewmodel.dart
│       │   └── widgets/
│       └── domain/           # Somente se a feature tiver regras específicas
├── shared/
│   ├── design_pattern/       # Command + Result (imutáveis)
│   ├── utils/environments/
│   ├── utils/interceptor/
│   └── widgets/              # Widgets compartilhados entre módulos
```

**Regra fundamental**: Nunca coloque lógica de negócio na View. Nunca acesse serviços externos diretamente do ViewModel — sempre via Repository.

---

## 2. Injeção de Dependências (get_it)

**Arquivo único**: `lib/injection.dart`

### 2.1 Padrão de Registro

```dart
final GetIt getIt = GetIt.instance;

void setupDependencyInjection() {
  // --- Services (externos, stateless ou com estado próprio) ---
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<DeviceCalendarService>(() => DeviceCalendarService());

  // --- Repositories (sempre LazySingleton, exceto se precisar de dispose) ---
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  getIt.registerLazySingleton<CalendarRepository>(() => CalendarRepositoryImpl());

  // --- ViewModels (sempre Factory — nova instância por navegação) ---
  getIt.registerFactory<LoginViewModel>(() => LoginViewModel());
  getIt.registerFactory<HomeViewModel>(() => HomeViewModel());
}
```

### 2.2 Regras de Registro

| Tipo | Registro get_it | Motivo |
|------|----------------|--------|
| Service externo | `registerLazySingleton` | Estado compartilhado/último, custoso recriar |
| Repository | `registerLazySingleton` | Mantém cache, streams, listeners |
| ViewModel | `registerFactory` | **Sempre nova instância** ao navegar. Evita estado residual entre telas |
| Database/Cliente HTTP | `registerLazySingleton` | Conexão persistente |

### 2.3 Padrão de Injeção no ViewModel (Constructor Injection com Fallback)

```dart
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? GetIt.instance<AuthRepository>();

  final AuthRepository _authRepository;
}
```

- **Sempre** aceite dependências como parâmetros opcionais nomeados (`{Repo? repo}`)
- **Sempre** faça fallback para `GetIt.instance<T>()`
- Isso permite mockar em testes unitários sem tocar no get_it global

### 2.4 Padrão de Injeção no RepositoryImpl

```dart
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthService? authService})
      : _authService = authService ?? GetIt.instance<AuthService>();

  final AuthService _authService;
}
```

- Repositories também recebem services opcionalmente para testes

---

## 3. Design Patterns Compartilhados

### 3.1 Result<T> — Resultado de Operações

**Arquivo**: `lib/shared/design_pattern/result.dart`

```dart
sealed class Result<T> {
  const factory Result.ok(T value) = Ok._;
  const factory Result.error(Exception error) = Error._;
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error._(this.error);
  final Exception error;
}
```

**Uso obrigatório**:
- Toda operação assíncrona de Repository/Service retorna `Result<T>`
- Nunca use `try/catch` na ViewModel para lógica de erro — deixe o Command tratar
- Use `switch` ou `if case` para desestruturar

```dart
Future<Result<AuthUserEntity>> signIn(...) async {
  final result = await _authService.signInWithPassword(...);
  switch (result) {
    case Ok<User>():
      return Result.ok(_toEntity(result.value));
    case Error<User>():
      return Result.error(result.error);
  }
}
```

### 3.2 Command<T> — Ações da UI

**Arquivo**: `lib/shared/design_pattern/command.dart`

```dart
// Command0 = ação sem argumento
// Command1 = ação com 1 argumento

late final Command0<void> signOutCommand = Command0<void>(_signOut);
late final Command1<AuthUserEntity, LoginCredentials> loginCommand =
    Command1<AuthUserEntity, LoginCredentials>(_login);
```

**Regras de Command**:
- 1 Command por ação de usuário (login, logout, refresh, submit)
- Command é `Listenable` — a View escuta mudanças de `running`, `completed`, `error`
- Sempre chame `command.dispose()` no `dispose()` do ViewModel
- Comandos nunca são expostos como métodos públicos — apenas via propriedade `late final`

**Padrão de escuta na View**:
```dart
@override
void initState() {
  super.initState();
  viewModel = GetIt.instance<LoginViewModel>();
  viewModel.loginCommand.addListener(_onLoginCommandChanged);
}

void _onLoginCommandChanged() {
  if (viewModel.loginCommand.running) return;
  if (viewModel.loginCommand.completed) {
    viewModel.loginCommand.clearResult();
    Navigator.pushReplacementNamed(context, AppRoute.home.path);
    return;
  }
  if (viewModel.loginCommand.error) {
    viewModel.loginCommand.clearResult();
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

---

## 4. Módulos Core (Transversais)

### 4.1 Estrutura Obrigatória

Todo módulo **core** deve ter esta estrutura exata:

```
modules/core/<nome>/
├── data/
│   ├── model/              # Se houver parsing JSON/Freezed
│   │   └── <model>.dart
│   │   └── <model>.freezed.dart
│   │   └── <model>.g.dart
│   └── service/
│       └── <nome>_service.dart
└── domain/
    ├── entity/
    │   └── <nome>_entity.dart
    └── repository/
        ├── <nome>_repository.dart       # abstract class
        └── <nome>_repository_impl.dart  # implements
```

### 4.2 Service (data/service/)

- Acesso direto a APIs externas, Firebase, SQLite, Bluetooth, etc.
- Nunca expõe `Result<T>` — pode lançar exceções ou retornar objetos brutos
- Preferencialmente recebe o cliente externo via construtor opcional

```dart
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Result<void>> signUp(...) async { ... } // ou lança exceção
}
```

### 4.3 Entity (domain/entity/)

- Pura, imutável, sem lógica de framework
- Use `const` constructor quando possível
- Não depende de `freezed` a menos que seja entity complexa

```dart
class AuthUserEntity {
  const AuthUserEntity({required this.id, required this.email, this.name});

  final String id;
  final String email;
  final String? name;

  String get initials {
    if (name == null || name!.isEmpty) return '';
    final parts = name!.trim().split(RegExp(r'\s+'));
    return parts.length == 1
        ? parts.first[0].toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
```

### 4.4 Repository (domain/repository/)

**Contrato (abstract)**:
```dart
abstract class AuthRepository {
  AuthUserEntity? get currentUser;
  Stream<AuthUserEntity?> get authStateChanges;
  Future<Result<void>> signUp({required String email, required String password, Map<String, dynamic>? data});
  Future<Result<AuthUserEntity>> signInWithEmailAndPassword({required String email, required String password});
  Future<Result<void>> sendPasswordResetEmail({required String email});
  Future<Result<void>> signOut();
}
```

**Implementação**:
```dart
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthService? authService})
      : _authService = authService ?? GetIt.instance<AuthService>();

  final AuthService _authService;

  @override
  AuthUserEntity? get currentUser { ... }

  @override
  Stream<AuthUserEntity?> get authStateChanges => ...

  @override
  Future<Result<AuthUserEntity>> signInWithEmailAndPassword(...) async {
    final result = await _authService.signInWithPassword(...);
    switch (result) {
      case Ok<User>():
        return Result.ok(_toEntity(result.value));
      case Error<User>():
        return Result.error(result.error);
    }
  }

  AuthUserEntity _toEntity(User user) => AuthUserEntity(...);
}
```

**Regra**: Repository nunca fala diretamente com Firebase/Dio/Bluetooth. Sempre via Service.

### 4.5 Model com Freezed (data/model/)

Use quando houver parsing JSON complexo:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'observation_model.freezed.dart';
part 'observation_model.g.dart';

@freezed
class ObservationModel with _$ObservationModel {
  const factory ObservationModel({
    required String id,
    required DateTime timestamp,
    required String roomId,
  }) = _ObservationModel;

  factory ObservationModel.fromJson(Map<String, dynamic> json) =>
      _$ObservationModelFromJson(json);
}
```

- Model pertence à camada `data` — converte para `Entity` no Repository
- Nunca exponha Model diretamente para ViewModel

---

## 5. Módulos de Tela (Features)

### 5.1 Estrutura Obrigatória

```
modules/<feature>/
├── <feature>_routes.dart
├── presenter/
│   ├── <feature>_view.dart
│   ├── <feature>_viewmodel.dart
│   └── widgets/
│       └── <feature>_<widget>.dart
└── domain/          # Somente se a tela tiver entidades/repositórios próprios
    ├── entity/
    └── repository/
```

### 5.2 Rotas (`<feature>_routes.dart`)

```dart
import 'package:flutter/material.dart';
import 'presenter/home_view.dart';

enum HomeRoute { home }

extension HomeRouteExtension on HomeRoute {
  String get path {
    switch (this) {
      case HomeRoute.home:
        return '/home';
    }
  }
}

final Map<String, WidgetBuilder> homeRoutes = {
  HomeRoute.home.path: (_) => const HomeView(),
};
```

**Regras**:
- 1 enum por módulo com os nomes das rotas
- 1 extension com `String get path`
- 1 `Map<String, WidgetBuilder>` exportado
- Agregue em `app_routes.dart` via spread operator `...homeRoutes`

### 5.3 ViewModel (`<feature>_viewmodel.dart`)

```dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../shared/design_pattern/command.dart';
import '../../../shared/design_pattern/result.dart';
import '../../core/auth/domain/repository/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? GetIt.instance<AuthRepository>();

  final AuthRepository _authRepository;

  late final Command1<AuthUserEntity, LoginCredentials> loginCommand =
      Command1<AuthUserEntity, LoginCredentials>(_login);

  Future<Result<AuthUserEntity>> _login(LoginCredentials credentials) async {
    return _authRepository.signInWithEmailAndPassword(
      email: credentials.email,
      password: credentials.password,
    );
  }

  @override
  void dispose() {
    loginCommand.dispose();
    super.dispose();
  }
}
```

**Regras de ViewModel**:
1. Extende `ChangeNotifier`
2. Recebe repos/services via construtor opcional + fallback get_it
3. Expõe dados via `get` (nunca `var` público mutável)
4. Usa `Command` para ações de UI
5. Gerencia Streams/StreamSubscription para dados reativos
6. Sempre chama `super.dispose()` no final
7. Use `bool _disposed = false` se houver timers/async pós-construção

**Padrão de StreamSubscription**:
```dart
bool _disposed = false;
late final StreamSubscription<void> _calendarSubscription;

ProfileViewModel({...}) {
  _calendarSubscription = _calendarRepository.changes.listen((_) {
    if (!_disposed) notifyListeners();
  });
}

@override
void dispose() {
  _disposed = true;
  _calendarSubscription.cancel();
  super.dispose();
}
```

**Padrão de inicialização lazy**:
```dart
ProfileViewModel({...}) {
  Future<void>.microtask(() async {
    if (_disposed) return;
    await Future.wait([
      initializeCalendarCommand.execute(),
      _myPresenceRepository.start(),
    ]);
  });
}
```

### 5.4 View (`<feature>_view.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../app_routes.dart';
import 'login_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginViewModel viewModel;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    viewModel = GetIt.instance<LoginViewModel>();
    viewModel.loginCommand.addListener(_onLoginCommandChanged);
  }

  @override
  void dispose() {
    viewModel.loginCommand.removeListener(_onLoginCommandChanged);
    viewModel.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onLoginCommandChanged() { ... }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => SingleChildScrollView(...),
        ),
      ),
    );
  }
}
```

**Regras de View**:
1. **Sempre** `StatefulWidget` — mesmo que aparentemente stateless
2. Obtém ViewModel via `GetIt.instance<ViewModel>()` no `initState`
3. Adiciona listeners de Command no `initState`, remove no `dispose`
4. Chama `viewModel.dispose()` antes de `super.dispose()`
5. Usa `ListenableBuilder` para escutar o ViewModel
6. Para ações de Command, usa `ListenableBuilder` específico no widget de ação
7. Navegação via `AppRoute.<nome>.path` — nunca string hardcoded
8. Layout responsivo: `ConstrainedBox(maxWidth: 560)` para conteúdo centralizado
9. Padding padrão de tela: `EdgeInsets.all(24)`
10. Espaçamento padrão entre seções: `SizedBox(height: 24)` ou `32`

### 5.5 Widgets Internos (`presenter/widgets/`)

```dart
class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    required this.label,
    required this.onPressed,
    required this.loading,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
```

- Widgets são `StatelessWidget` sempre que possível
- Recebem dados primitivos/entities — nunca ViewModel inteiro
- Nome: `<feature>_<descricao>.dart`

---

## 6. Rotas (`app_routes.dart`)

```dart
import 'package:flutter/material.dart';

import 'modules/home/home_routes.dart';
import 'modules/login/login_routes.dart';
// ... outros imports

enum AppRoute {
  welcome,
  login,
  register,
  home,
  // ...
}

extension AppRouteExtension on AppRoute {
  String get path {
    switch (this) {
      case AppRoute.welcome:
        return WelcomeRoute.welcome.path;
      case AppRoute.login:
        return LoginRoute.login.path;
      // ...
    }
  }
}

final Map<String, WidgetBuilder> appRoutes = {
  ...welcomeRoutes,
  ...loginRoutes,
  ...homeRoutes,
  // ...
};
```

**Regras**:
- Enum central `AppRoute` lista todas as rotas do app
- Cada módulo define seu próprio enum/path/map
- `app_routes.dart` apenas agrega via spread operator
- Nunca defina rotas diretamente em `app_routes.dart`

---

## 7. Tratamento de Erros e Exceções

### 7.1 Estrutura

```dart
// lib/modules/core/<modulo>/domain/<modulo>_exceptions.dart

class DomainNotAllowedException implements Exception {
  const DomainNotAllowedException();
  static const String userMessage = 'O email informado não é permitido.';
}
```

### 7.2 Mapeamento em Service

```dart
Exception mapFirebaseAuthException(FirebaseAuthException exception) {
  switch (exception.code) {
    case 'email-not-verified':
      return const EmailNotVerifiedException();
    default:
      return Exception(exception.message ?? exception.code);
  }
}
```

### 7.3 Apresentação na View

```dart
String _errorMessage(Result<dynamic>? result) {
  if (result is! Error) return 'Erro desconhecido.';
  final error = result.error;
  if (error is EmailNotVerifiedException) {
    return EmailNotVerifiedException.userMessage;
  }
  return 'Não foi possível entrar. Verifique suas credenciais.';
}
```

---

## 8. Testes Unitários

### 8.1 Estrutura de Teste de ViewModel

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:anota_who/modules/core/auth/domain/entity/auth_user_entity.dart';
import 'package:anota_who/modules/core/auth/domain/repository/auth_repository.dart';
import 'package:anota_who/modules/login/presenter/login_viewmodel.dart';
import 'package:anota_who/shared/design_pattern/result.dart';

class FakeAuthRepository implements AuthRepository {
  final bool shouldSucceed;
  FakeAuthRepository({this.shouldSucceed = true});

  @override
  Future<Result<AuthUserEntity>> signInWithEmailAndPassword(...) async {
    if (shouldSucceed) {
      return Result.ok(AuthUserEntity(id: 'user-123', email: email));
    }
    return Result.error(Exception('Invalid credentials'));
  }

  // Implemente todos os membros do contrato (use Result.error(Exception('unused')) para os não usados)
}

void main() {
  group('LoginViewModel', () {
    test('loginCommand succeeds with valid credentials', () async {
      final fakeRepo = FakeAuthRepository(shouldSucceed: true);
      final viewModel = LoginViewModel(authRepository: fakeRepo);

      await viewModel.loginCommand.execute(
        const LoginCredentials(email: 'test@example.com', password: 'pass123'),
      );

      expect(viewModel.loginCommand.completed, isTrue);
      expect(viewModel.loginCommand.error, isFalse);
    });
  });
}
```

### 8.2 Regras de Teste

- **Nunca** use `get_it` em testes unitários de ViewModel
- Sempre passe mocks via construtor
- FakeImplementations são preferidas a Mockito neste projeto
- Testes de ViewModel devem cobrir: sucesso, erro, estados do Command
- Testes de Repository devem cobrir: mapeamento de dados, tratamento de exceções

### 8.3 Support Files (`test/support/`)

Crie Fakes reutilizáveis para entidades complexas:

```dart
// test/support/presence_test_support.dart
class FakeMyPresenceRepository implements MyPresenceRepository { ... }
class FakeHomeFriendsRepository implements HomeFriendsRepository { ... }
```

---

## 9. Checklist para Criar Novo Módulo

### Módulo Core (ex: `modules/core/new_feature/`)

- [ ] Criar `data/service/<nome>_service.dart` — acesso externo
- [ ] Criar `domain/entity/<nome>_entity.dart` — dados puros
- [ ] Criar `domain/repository/<nome>_repository.dart` — contrato abstract
- [ ] Criar `domain/repository/<nome>_repository_impl.dart` — implementação com fallback get_it
- [ ] Se houver JSON: criar `data/model/<nome>_model.dart` com freezed
- [ ] Registrar service e repository em `injection.dart`
- [ ] Criar testes unitários para RepositoryImpl

### Módulo de Tela (ex: `modules/new_screen/`)

- [ ] Criar `<screen>_routes.dart` com enum + extension + map
- [ ] Criar `presenter/<screen>_viewmodel.dart` — ChangeNotifier + Command
- [ ] Criar `presenter/<screen>_view.dart` — StatefulWidget + ListenableBuilder
- [ ] Criar widgets internos em `presenter/widgets/`
- [ ] Registrar ViewModel como `registerFactory` em `injection.dart`
- [ ] Adicionar rotas em `app_routes.dart` via spread
- [ ] Criar testes unitários para ViewModel com Fake repositories

### Navegação

- [ ] Usar `AppRoute.<nome>.path` em vez de strings
- [ ] Para navegação com replacement: `Navigator.pushReplacementNamed`
- [ ] Para logout/reset: `Navigator.pushNamedAndRemoveUntil(..., (route) => false)`

---

## 10. Convenções de Código

| Aspecto | Convenção |
|---------|-----------|
| Imports | Relativos (`../../../`) para arquivos do projeto |
| Nomenclatura | `PascalCase` para classes, `camelCase` para membros, `snake_case` para arquivos |
| Entities | Sufixo `Entity` (ex: `AuthUserEntity`) |
| Models | Sufixo `Model` (ex: `ObservationModel`) |
| Repositories | Prefixo do domínio + `Repository` (ex: `AuthRepository`) |
| Repositories Impl | `RepositoryImpl` (ex: `AuthRepositoryImpl`) |
| Services | Sufixo `Service` (ex: `AuthService`) |
| ViewModels | Sufixo `ViewModel` (ex: `LoginViewModel`) |
| Views | Sufixo `View` (ex: `LoginView`) |
| Widgets | Prefixo da feature + descrição (ex: `login_submit_button.dart`) |
| Nullable | Use `?` explicitamente. Evite `late` não inicializado |
| Streams | Sempre cancele `StreamSubscription` no `dispose` |
| Async | Prefira `unawaited()` para chamadas fire-and-forget |

---

## 11. Exemplos de Padrões Comuns

### 11.1 ViewModel com múltiplos repositories

```dart
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    AuthRepository? authRepository,
    CalendarRepository? calendarRepository,
  })  : _authRepository = authRepository ?? GetIt.instance<AuthRepository>(),
        _calendarRepository = calendarRepository ?? GetIt.instance<CalendarRepository>();

  final AuthRepository _authRepository;
  final CalendarRepository _calendarRepository;
  // ...
}
```

### 11.2 ViewModel com Stream reativo

```dart
late final StreamSubscription<List<PresenceEntity>> _friendsSubscription;

HomeViewModel({...}) {
  _friendsSubscription = _homeFriendsRepository.changes.listen((_) {
    if (!_disposed) notifyListeners();
  });
}
```

### 11.3 View com lifecycle observer

```dart
class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      viewModel.resume();
    }
  }
}
```

### 11.4 Model Freezed com conversão para Entity

```dart
// data/model/person_model.dart
@freezed
class PersonModel with _$PersonModel {
  const factory PersonModel({required String id, required String name}) = _PersonModel;
  factory PersonModel.fromJson(Map<String, dynamic> json) => _$PersonModelFromJson(json);
}

// domain/entity/person_entity.dart
class PersonEntity {
  const PersonEntity({required this.id, required this.name});
  final String id;
  final String name;
}

// repository_impl.dart
PersonEntity _toEntity(PersonModel model) => PersonEntity(id: model.id, name: model.name);
```

---

## 12. NÃO FAÇA (Anti-padrões)

- ❌ Não use `context.read`/`context.watch` (Provider) — este projeto usa get_it + ListenableBuilder
- ❌ Não exponha `StreamController` público — use `Stream` ou `ValueListenable`
- ❌ Não chame `notifyListeners()` dentro de `build()`
- ❌ Não use `setState` na View quando houver ViewModel — use `ListenableBuilder`
- ❌ Não registre ViewModel como `LazySingleton` — use `Factory`
- ❌ Não acesse `GetIt.instance` diretamente em Services/Entities
- ❌ Não misture Model (data) com Entity (domain) na UI
- ❌ Não deixe StreamSubscription sem cancelamento no dispose
- ❌ Não use `var` público mutável no ViewModel — use getters
- ❌ Não coloque regras de negócio na View

---

*Documento gerado a partir da análise da base de código atual. Siga estritamente para manter consistência na refatoração.*
