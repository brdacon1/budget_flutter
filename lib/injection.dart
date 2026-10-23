import 'package:get_it/get_it.dart';

/// Instância global do GetIt para injeção de dependências.
///
/// Regras de registro:
/// - Services externos / compartilhados → `registerLazySingleton`
/// - Repositories (abstrações + impl)   → `registerLazySingleton`
/// - ViewModels                         → `registerFactory` (sempre nova instância)
///
/// ViewModels devem aceitar dependências opcionais no construtor com
/// fallback para `getIt<Dependency>()`, permitindo mocks em testes.
final GetIt getIt = GetIt.instance;

/// Configura todas as dependências do aplicativo.
///
/// Chamado uma única vez no `main()` antes de `runApp`.
void setupDependencyInjection() {
  // ------------------------------------------------------------------
  // Core Services (stateless ou com estado próprio, custosos de recriar)
  // ------------------------------------------------------------------
  // Exemplo:
  // getIt.registerLazySingleton<HttpRequest>(() => HttpRequest());

  // ------------------------------------------------------------------
  // Core Repositories
  // ------------------------------------------------------------------
  // Exemplo:
  // getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

  // ------------------------------------------------------------------
  // Feature ViewModels (sempre Factory)
  // ------------------------------------------------------------------
  // Exemplo:
  // getIt.registerFactory<LoginViewModel>(() => LoginViewModel());
}
