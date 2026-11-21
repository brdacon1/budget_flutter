import 'package:get_it/get_it.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:oflite/modules/dashboard/data/repository/dashboard_repository_impl.dart';
import 'package:oflite/modules/dashboard/domain/repository/dashboard_repository.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_dashboard_month_summary_usecase.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_receipts_comparison_usecase.dart';
import 'package:oflite/modules/dashboard/presenter/dashboard_view_model.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_ledger_repository.dart';

/// Registra as dependências do módulo Dashboard.
void registerDashboardDependencies(GetIt sl) {
  sl.registerLazySingleton<DashboardRemoteDatasource>(
    () => DashboardRemoteDatasource(),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      sl<DashboardRemoteDatasource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerLazySingleton<GetDashboardMonthSummaryUsecase>(
    () => GetDashboardMonthSummaryUsecase(
      sl<BudgetRepository>(),
      sl<ReceiptLedgerRepository>(),
      sl<DashboardRepository>(),
    ),
  );
  sl.registerLazySingleton<GetReceiptsComparisonUsecase>(
    () => GetReceiptsComparisonUsecase(
      sl<BudgetRepository>(),
      sl<ReceiptLedgerRepository>(),
    ),
  );
  sl.registerFactory<DashboardViewModel>(
    () => DashboardViewModel(
      sl<GetDashboardMonthSummaryUsecase>(),
      sl<GetReceiptsComparisonUsecase>(),
    ),
  );
}
