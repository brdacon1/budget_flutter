import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/budget_binds.dart';
import 'package:oflite/modules/chat_budget/chat_budget_binds.dart';
import 'package:oflite/modules/comment/comment_binds.dart';
import 'package:oflite/modules/core/core_binds.dart';
import 'package:oflite/modules/login/login_binds.dart';
import 'package:oflite/modules/payment/payment_binds.dart';
import 'package:oflite/modules/pdf/pdf_binds.dart';
import 'package:oflite/modules/product/product_binds.dart';
import 'package:oflite/modules/receipt/receipt_binds.dart';

/// Instância global do GetIt para injeção de dependências.
///
/// Regras de registro:
/// - DataSources externos / compartilhados → `registerLazySingleton`
/// - Repositories (abstrações + impl)   → `registerLazySingleton` (mantêm cache em memória)
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
  registerCoreDependencies(getIt);

  // ------------------------------------------------------------------
  // Feature Binds (Datasource -> RepositoryImpl exposta como interface)
  // ------------------------------------------------------------------
  registerBudgetDependencies(getIt);
  registerReceiptDependencies(getIt);
  registerPaymentDependencies(getIt);
  registerProductDependencies(getIt);
  registerCommentDependencies(getIt);
  registerPdfDependencies(getIt);
  registerLoginDependencies(getIt);
  registerChatBudgetDependencies(getIt);

  // ------------------------------------------------------------------
  // Feature ViewModels (sempre Factory)
  // ------------------------------------------------------------------
  // Cada ViewModel é registrado no binds do próprio módulo ou aqui
  // caso precise ser centralizado.
}
