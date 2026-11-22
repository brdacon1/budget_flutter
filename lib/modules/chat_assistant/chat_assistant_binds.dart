import 'package:oflite/modules/chat_assistant/domain/usecase/show_comment_library_menu_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/format_document_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/validate_document_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_comment_library_menu_option_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/get_month_summary_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/update_budget_status_usecase.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/chat_ai_local_datasource.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/chat_ai_remote_datasource.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/confirm_agent_action_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/dispatch_agent_tool_usecase.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/duplicate_budget_usecase.dart';
import 'package:oflite/modules/receipt/domain/usecase/create_receipt_for_budget_usecase.dart';
import 'package:oflite/modules/receipt/domain/usecase/get_receipts_report_usecase.dart';
import 'package:oflite/modules/receipt/domain/usecase/list_receipts_by_budget_usecase.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/chat_budget_remote_datasource.dart';
import 'package:oflite/modules/chat_assistant/data/repository/chat_ai_repository_impl.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/check_ai_access_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/run_agent_turn_usecase.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/chat_script_remote_datasource.dart';
import 'package:oflite/modules/chat_assistant/data/repository/chat_budget_repository_impl.dart';
import 'package:oflite/modules/chat_assistant/data/repository/chat_script_repository_impl.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_script_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/build_budget_final_actions_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/create_budget_from_chat_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/generate_budget_pdf_from_chat_usecase.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/fetch_chat_script_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_change_username_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_logo_menu_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_main_menu_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_pdf_edit_confirm_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_pdf_edit_menu_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_pdf_field_input_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_price_list_menu_option_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/on_logo_updated_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/reset_chat_to_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/resolve_ai_failure_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_find_budget_prompt_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_reports_prompt_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_change_username_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_logo_in_chat_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_pdf_edit_confirm_entry_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_pdf_edit_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_price_list_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/start_budget_from_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/update_pdf_field_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/chat_assistant_view_model.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_budget_picker/chat_budget_picker_view_model.dart';

import 'package:oflite/modules/chat_assistant/data/datasource/device_media_datasource.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/shared_media_datasource.dart';
import 'package:oflite/modules/chat_assistant/data/repository/chat_media_repository_impl.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_media_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/pick_proof_attachments_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/receive_shared_proof_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/load_gallery_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_media_picker/chat_media_picker_view_model.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/check_proof_limit_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/create_payment_proof_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/parse_money_input_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';

/// Registra as dependências do módulo Chat Budget (Assistente).
void registerChatBudgetDependencies(GetIt sl) {
  sl.registerLazySingleton(() => DeviceMediaDatasource());
  sl.registerLazySingleton(() => SharedMediaDatasource());
  sl.registerLazySingleton<ChatMediaRepository>(
    () => ChatMediaRepositoryImpl(
      sl<DeviceMediaDatasource>(),
      sl<SharedMediaDatasource>(),
    ),
  );
  sl.registerLazySingleton(
    () => PickProofAttachmentsUsecase(
      sl<ChatMediaRepository>(),
      sl<ValidateProofAttachmentsUsecase>(),
    ),
  );
  sl.registerLazySingleton(() => LoadGalleryUsecase(sl<ChatMediaRepository>()));
  sl.registerFactory(
    () => ChatMediaPickerViewModel(
      sl<LoadGalleryUsecase>(),
      sl<PickProofAttachmentsUsecase>(),
    ),
  );
  sl.registerLazySingleton(
    () => ReceiveSharedProofUsecase(
      sl<ChatMediaRepository>(),
      sl<ValidateProofAttachmentsUsecase>(),
      sl<CheckAiAccessUsecase>(),
    ),
  );

  // ------------------------------------------------------------------
  // DataSources
  // ------------------------------------------------------------------
  sl.registerLazySingleton<ChatScriptRemoteDataSource>(
    () => ChatScriptRemoteDataSource(),
  );
  sl.registerLazySingleton<ChatBudgetRemoteDataSource>(
    () => ChatBudgetRemoteDataSource(),
  );
  sl.registerLazySingleton<ChatAiRemoteDatasource>(
    () => ChatAiRemoteDatasource(),
  );
  sl.registerLazySingleton<ChatAiLocalDatasource>(
    () => ChatAiLocalDatasource(),
  );

  // ------------------------------------------------------------------
  // Repositories (interface -> implementation)
  // ------------------------------------------------------------------
  sl.registerLazySingleton<ChatScriptRepository>(
    () => ChatScriptRepositoryImpl(
      sl<ChatScriptRemoteDataSource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerLazySingleton<ChatAiRepository>(
    () => ChatAiRepositoryImpl(
      sl<ChatAiRemoteDatasource>(),
      sl<ChatAiLocalDatasource>(),
    ),
  );
  sl.registerLazySingleton<ChatBudgetRepository>(
    () => ChatBudgetRepositoryImpl(
      sl<ChatBudgetRemoteDataSource>(),
      sl<BudgetRepository>(),
      sl<UserRepository>(),
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
  sl.registerLazySingleton<ShowPdfEditConfirmEntryUsecase>(
    () => ShowPdfEditConfirmEntryUsecase(
      sl<ChatBudgetRepository>(),
      sl<PdfRepository>(),
    ),
  );
  sl.registerLazySingleton<ShowChangeUsernameMenuUsecase>(
    () => ShowChangeUsernameMenuUsecase(
      sl<ChatBudgetRepository>(),
      sl<UserRepository>(),
    ),
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
      sl<ShowPdfEditConfirmEntryUsecase>(),
      sl<ShowPdfEditMenuUsecase>(),
      sl<ShowChangeUsernameMenuUsecase>(),
      sl<ResetChatToMenuUsecase>(),
    ),
  );
  sl.registerLazySingleton<ShowCommentLibraryMenuUsecase>(
    () => ShowCommentLibraryMenuUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<HandleCommentLibraryMenuOptionUsecase>(
    () => const HandleCommentLibraryMenuOptionUsecase(),
  );
  sl.registerLazySingleton<HandlePriceListMenuOptionUsecase>(
    () => const HandlePriceListMenuOptionUsecase(),
  );
  sl.registerLazySingleton<HandlePdfEditMenuOptionUsecase>(
    () => HandlePdfEditMenuOptionUsecase(
      sl<ChatBudgetRepository>(),
      sl<PdfRepository>(),
    ),
  );
  sl.registerLazySingleton<HandlePdfFieldInputUsecase>(
    () => HandlePdfFieldInputUsecase(
      sl<UpdatePdfFieldUsecase>(),
      sl<ChatBudgetRepository>(),
      sl<ValidateDocumentUsecase>(),
      sl<FormatDocumentUsecase>(),
    ),
  );
  sl.registerLazySingleton<HandlePdfEditConfirmOptionUsecase>(
    () => HandlePdfEditConfirmOptionUsecase(sl<ShowPdfEditMenuUsecase>()),
  );
  sl.registerLazySingleton<HandleChangeUsernameOptionUsecase>(
    () => HandleChangeUsernameOptionUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<ShowLogoInChatUsecase>(
    () =>
        ShowLogoInChatUsecase(sl<PdfRepository>(), sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<HandleLogoMenuOptionUsecase>(
    () => HandleLogoMenuOptionUsecase(
      sl<ChatBudgetRepository>(),
      sl<ShowLogoInChatUsecase>(),
    ),
  );
  sl.registerLazySingleton<OnLogoUpdatedUsecase>(
    () => OnLogoUpdatedUsecase(
      sl<ChatBudgetRepository>(),
      sl<ShowLogoInChatUsecase>(),
    ),
  );

  sl.registerLazySingleton<BuildBudgetFinalActionsUsecase>(
    () => BuildBudgetFinalActionsUsecase(sl<AdsRepository>()),
  );
  sl.registerLazySingleton<GenerateBudgetPdfFromChatUsecase>(
    () => GenerateBudgetPdfFromChatUsecase(
      sl<ChatBudgetRepository>(),
      sl<BudgetRepository>(),
      sl<AdsRepository>(),
    ),
  );

  // ------------------------------------------------------------------
  // Usecases IA (assinantes)
  // ------------------------------------------------------------------
  sl.registerLazySingleton<CheckAiAccessUsecase>(
    () => CheckAiAccessUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<DispatchAgentToolUsecase>(
    () => DispatchAgentToolUsecase(
      sl<ListBudgetsUsecase>(),
      sl<GetMonthSummaryUsecase>(),
      sl<ListReceiptsByBudgetUsecase>(),
      sl<BudgetRepository>(),
      sl<ShareLinkRepository>(),
      sl<ConvertCoinRepository>(),
      sl<GetReceiptsReportUsecase>(),
    ),
  );
  sl.registerLazySingleton<RunAgentTurnUsecase>(
    () => RunAgentTurnUsecase(
      sl<ChatAiRepository>(),
      sl<UserRepository>(),
      sl<DispatchAgentToolUsecase>(),
    ),
  );
  sl.registerLazySingleton<ShowReportsPromptUsecase>(
    () => ShowReportsPromptUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<ShowFindBudgetPromptUsecase>(
    () => ShowFindBudgetPromptUsecase(sl<ChatBudgetRepository>()),
  );
  sl.registerLazySingleton<ResolveAiFailureUsecase>(
    () => const ResolveAiFailureUsecase(),
  );
  sl.registerLazySingleton<ConfirmAgentActionUsecase>(
    () => ConfirmAgentActionUsecase(
      sl<ChatAiRepository>(),
      sl<CreateReceiptForBudgetUsecase>(),
      sl<UpdateBudgetStatusUsecase>(),
    ),
  );

  // ------------------------------------------------------------------
  // ViewModels (Factory)
  // ------------------------------------------------------------------
  sl.registerFactory<ChatBudgetPickerViewModel>(
    () => ChatBudgetPickerViewModel(
      sl<ListBudgetsUsecase>(),
      sl<ConvertCoinRepository>(),
    ),
  );
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
      sl<ShowPdfEditMenuUsecase>(),
      sl<HandlePdfFieldInputUsecase>(),
      sl<HandlePdfEditConfirmOptionUsecase>(),
      sl<HandleChangeUsernameOptionUsecase>(),
      sl<HandleLogoMenuOptionUsecase>(),
      sl<OnLogoUpdatedUsecase>(),
      sl<PdfRepository>(),
      sl<ChatAiRepository>(),
      sl<CheckAiAccessUsecase>(),
      sl<RunAgentTurnUsecase>(),
      sl<ConfirmAgentActionUsecase>(),
      sl<ResolveAiFailureUsecase>(),
      sl<ShowReportsPromptUsecase>(),
      sl<DuplicateBudgetUsecase>(),
      sl<ShowFindBudgetPromptUsecase>(),
      sl<BuildBudgetFinalActionsUsecase>(),
      sl<GenerateBudgetPdfFromChatUsecase>(),
      sl<CheckProofLimitUsecase>(),
      sl<CreatePaymentProofUsecase>(),
      sl<ParseMoneyInputUsecase>(),
      sl<PickProofAttachmentsUsecase>(),
      sl<ReceiveSharedProofUsecase>(),
      sl<FormatDocumentUsecase>(),
    ),
  );
}
