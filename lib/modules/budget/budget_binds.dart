import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/data/datasource/budget_comment_remote_datasource.dart';
import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/budget/data/repository/budget_comment_repository_impl.dart';
import 'package:oflite/modules/budget/data/repository/budget_repository_impl.dart';
import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';

import 'presenter/budget_list/budget_list_view_model.dart';
import 'presenter/budget_tab/budget_tab_view_model.dart';

/// Registra as dependências do módulo Budget (orçamentos).
void registerBudgetDependencies(GetIt sl) {
  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSource(),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      sl<BudgetRemoteDataSource>(),
      sl<UserRepository>(),
    ),
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
}
