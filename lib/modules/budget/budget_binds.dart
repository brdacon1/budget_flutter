import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/budget/data/datasource/comment_remote_datasource.dart';
import 'package:oflite/modules/budget/data/repository/budget_repository_impl.dart';
import 'package:oflite/modules/budget/data/repository/comment_repository_impl.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/domain/repository/comment_repository.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';

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

  sl.registerLazySingleton<CommentRemoteDataSource>(
    () => CommentRemoteDataSource(),
  );
  sl.registerLazySingleton<CommentRepository>(
    () => CommentRepositoryImpl(
      sl<CommentRemoteDataSource>(),
      sl<UserRepository>(),
    ),
  );
}
