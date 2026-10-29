import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/chat_budget/data/datasource/chat_budget_remote_datasource.dart';
import 'package:oflite/modules/chat_budget/data/datasource/chat_script_remote_datasource.dart';
import 'package:oflite/modules/chat_budget/data/repository/chat_budget_repository_impl.dart';
import 'package:oflite/modules/chat_budget/data/repository/chat_script_repository_impl.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_script_repository.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/create_budget_from_chat_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/fetch_chat_script_usecase.dart';
import 'package:oflite/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart';

/// Registra as dependências do módulo Chat Budget (Assistente).
void registerChatBudgetDependencies(GetIt sl) {
  // ------------------------------------------------------------------
  // DataSources
  // ------------------------------------------------------------------
  sl.registerLazySingleton<ChatScriptRemoteDataSource>(
    () => ChatScriptRemoteDataSource(),
  );
  sl.registerLazySingleton<ChatBudgetRemoteDataSource>(
    () => ChatBudgetRemoteDataSource(),
  );

  // ------------------------------------------------------------------
  // Repositories (interface -> implementation)
  // ------------------------------------------------------------------
  sl.registerLazySingleton<ChatScriptRepository>(
    () => ChatScriptRepositoryImpl(sl<ChatScriptRemoteDataSource>()),
  );
  sl.registerLazySingleton<ChatBudgetRepository>(
    () => ChatBudgetRepositoryImpl(
      sl<ChatBudgetRemoteDataSource>(),
      sl<BudgetRepository>(),
    ),
  );

  // ------------------------------------------------------------------
  // Usecases
  // ------------------------------------------------------------------
  sl.registerLazySingleton<FetchChatScriptUsecase>(
    () => FetchChatScriptUsecase(sl<ChatScriptRepository>()),
  );
  sl.registerLazySingleton<CreateBudgetFromChatUsecase>(
    () => CreateBudgetFromChatUsecase(
      sl<ChatBudgetRepository>(),
      sl<ChatScriptRepository>(),
    ),
  );

  // ------------------------------------------------------------------
  // ViewModels (Factory)
  // ------------------------------------------------------------------
  sl.registerFactory<ChatAssistantViewModel>(
    () => ChatAssistantViewModel(
      sl<ChatBudgetRepository>(),
      sl<ChatScriptRepository>(),
      sl<CreateBudgetFromChatUsecase>(),
      sl<FetchChatScriptUsecase>(),
    ),
  );
}
