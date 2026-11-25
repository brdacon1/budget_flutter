import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/presenter/budget_draft_notifier.dart';
import 'package:oflite/modules/budget/data/datasource/budget_comment_remote_datasource.dart';
import 'package:oflite/modules/budget/data/datasource/budget_metrics_remote_datasource.dart';
import 'package:oflite/modules/budget/data/repository/budget_metrics_repository_impl.dart';
import 'package:oflite/modules/budget/domain/repository/budget_metrics_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/get_budget_metrics_usecase.dart';
import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/budget/data/repository/budget_comment_repository_impl.dart';
import 'package:oflite/modules/budget/data/repository/budget_repository_impl.dart';
import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/add_price_items_to_budget_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/create_budget_for_customer_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/watch_customer_budgets_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/duplicate_budget_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/get_month_summary_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_page_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/update_budget_status_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/update_budget_item_quantity_usecase.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';

import 'presenter/budget_list/budget_list_view_model.dart';
import 'presenter/budget_tab/budget_tab_view_model.dart';

/// Registra as dependências do módulo Budget (orçamentos).
void registerBudgetDependencies(GetIt sl) {
  sl.registerLazySingleton<BudgetDraftNotifier>(() => BudgetDraftNotifier());
  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSource(),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      sl<BudgetRemoteDataSource>(),
      sl<UserRepository>(),
    ),
  );

  sl.registerFactory<DuplicateBudgetUsecase>(
    () =>
        DuplicateBudgetUsecase(sl<BudgetRepository>(), sl<ReceiptRepository>()),
  );

  sl.registerFactory<UpdateBudgetItemQuantityUsecase>(
    () => UpdateBudgetItemQuantityUsecase(sl<BudgetRepository>()),
  );

  sl.registerFactory<WatchCustomerBudgetsUsecase>(
    () => WatchCustomerBudgetsUsecase(sl<BudgetRepository>()),
  );

  sl.registerFactory<CreateBudgetForCustomerUsecase>(
    () => CreateBudgetForCustomerUsecase(sl<BudgetRepository>()),
  );

  sl.registerFactory<AddPriceItemsToBudgetUsecase>(
    () => AddPriceItemsToBudgetUsecase(sl<BudgetRepository>()),
  );

  sl.registerLazySingleton<ListBudgetsUsecase>(
    () => ListBudgetsUsecase(sl<BudgetRepository>()),
  );
  sl.registerLazySingleton<ListBudgetsPageUsecase>(
    () => ListBudgetsPageUsecase(
      sl<BudgetRepository>(),
      sl<ListBudgetsUsecase>(),
    ),
  );
  sl.registerLazySingleton<GetMonthSummaryUsecase>(
    () => GetMonthSummaryUsecase(sl<ListBudgetsUsecase>()),
  );
  sl.registerLazySingleton<UpdateBudgetStatusUsecase>(
    () => UpdateBudgetStatusUsecase(sl<BudgetRepository>()),
  );

  // ViewModels
  sl.registerFactory<BudgetListViewModel>(() => BudgetListViewModel());
  sl.registerFactory<BudgetTabViewModel>(() => BudgetTabViewModel());

  sl.registerLazySingleton<BudgetCommentRemoteDatasource>(
    () => BudgetCommentRemoteDatasource(),
  );
  sl.registerLazySingleton<BudgetCommentRepository>(
    () => BudgetCommentRepositoryImpl(
      sl<BudgetCommentRemoteDatasource>(),
      sl<UserRepository>(),
    ),
  );

  sl.registerLazySingleton<BudgetMetricsRemoteDatasource>(
    () => BudgetMetricsRemoteDatasource(),
  );
  sl.registerLazySingleton<BudgetMetricsRepository>(
    () => BudgetMetricsRepositoryImpl(
      sl<BudgetMetricsRemoteDatasource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerFactory<GetBudgetMetricsUsecase>(
    () => GetBudgetMetricsUsecase(sl<BudgetMetricsRepository>()),
  );
}
