import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/budget/data/repository/budget_repository_impl.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/budget_list/presenter/budget_list_view_model.dart';
import 'package:oflite/modules/budget/budget_tab/presenter/budget_tab_view_model.dart';

/// Registra as dependências do módulo Budget (orçamentos).
void registerBudgetDependencies(GetIt sl) {
  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSource(),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(sl<BudgetRemoteDataSource>()),
  );

  // ViewModels
  sl.registerFactory<BudgetListViewModel>(() => BudgetListViewModel());
  sl.registerFactory<BudgetTabViewModel>(() => BudgetTabViewModel());
}
