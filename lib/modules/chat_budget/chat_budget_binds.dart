import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/chat_budget/data/datasource/chat_budget_remote_datasource.dart';
import 'package:oflite/modules/chat_budget/data/datasource/chat_script_remote_datasource.dart';
import 'package:oflite/modules/chat_budget/data/repository/chat_budget_repository_impl.dart';
import 'package:oflite/modules/chat_budget/data/repository/chat_script_repository_impl.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_script_repository.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/create_budget_from_chat_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/fetch_chat_script_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/handle_change_username_option_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/handle_logo_menu_option_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/handle_main_menu_option_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/handle_pdf_edit_confirm_option_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/handle_pdf_edit_menu_option_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/handle_pdf_field_input_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/handle_price_list_menu_option_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/on_logo_updated_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/reset_chat_to_menu_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/show_change_username_menu_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/show_logo_in_chat_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/show_pdf_edit_menu_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/show_price_list_menu_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/start_budget_from_menu_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/update_pdf_field_usecase.dart';
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
  // Usecases existing
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
  sl.registerLazySingleton<StartBudgetFromMenuUsecase>(
    () => StartBudgetFromMenuUsecase(
      sl<ChatBudgetRepository>(),
      sl<ChatScriptRepository>(),
    ),
  );
  sl.registerLazySingleton<ShowPriceListMenuUsecase>(
    () => ShowPriceListMenuUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<ShowPdfEditMenuUsecase>(
    () => ShowPdfEditMenuUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<ShowChangeUsernameMenuUsecase>(
    () => ShowChangeUsernameMenuUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<ResetChatToMenuUsecase>(
    () => ResetChatToMenuUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<UpdatePdfFieldUsecase>(
    () => UpdatePdfFieldUsecase(sl<PdfRepository>()),
  );

  // ------------------------------------------------------------------
  // Usecases new
  // ------------------------------------------------------------------
  sl.registerLazySingleton<HandleMainMenuOptionUsecase>(
    () => HandleMainMenuOptionUsecase(
      sl<StartBudgetFromMenuUsecase>(),
      sl<ShowPriceListMenuUsecase>(),
      sl<ShowPdfEditMenuUsecase>(),
      sl<ShowChangeUsernameMenuUsecase>(),
      sl<ResetChatToMenuUsecase>(),
    ),
  );
  sl.registerLazySingleton<HandlePriceListMenuOptionUsecase>(
    () => const HandlePriceListMenuOptionUsecase(),
  );
  sl.registerLazySingleton<HandlePdfEditMenuOptionUsecase>(
    () => HandlePdfEditMenuOptionUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<HandlePdfFieldInputUsecase>(
    () => HandlePdfFieldInputUsecase(
      sl<UpdatePdfFieldUsecase>(),
      sl<ChatBudgetRepository>(),
    ),
  );
  sl.registerLazySingleton<HandlePdfEditConfirmOptionUsecase>(
    () => HandlePdfEditConfirmOptionUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<HandleChangeUsernameOptionUsecase>(
    () => HandleChangeUsernameOptionUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<ShowLogoInChatUsecase>(
    () => ShowLogoInChatUsecase(
      sl<PdfRepository>(),
      sl<ChatBudgetRepository>(),
    ),
  );
  sl.registerLazySingleton<HandleLogoMenuOptionUsecase>(
    () => HandleLogoMenuOptionUsecase(
      sl<ChatBudgetRepository>(),
      sl<ShowLogoInChatUsecase>(),
    ),
  );
  sl.registerLazySingleton<OnLogoUpdatedUsecase>(
    () => OnLogoUpdatedUsecase(sl<ChatBudgetRepository>()),
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
      sl<ShowPriceListMenuUsecase>(),
      sl<ResetChatToMenuUsecase>(),
      sl<HandleMainMenuOptionUsecase>(),
      sl<HandlePriceListMenuOptionUsecase>(),
      sl<HandlePdfEditMenuOptionUsecase>(),
      sl<HandlePdfFieldInputUsecase>(),
      sl<HandlePdfEditConfirmOptionUsecase>(),
      sl<HandleChangeUsernameOptionUsecase>(),
      sl<HandleLogoMenuOptionUsecase>(),
      sl<OnLogoUpdatedUsecase>(),
    ),
  );
}
