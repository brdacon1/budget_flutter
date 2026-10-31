import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/data/datasource/pdf_remote_datasource.dart';
import 'package:oflite/modules/pdf/data/repository/pdf_repository_impl.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_receipt_usecase.dart';
import 'package:oflite/modules/pdf/pdf_budget/presenter/pdf_budget_view_model.dart';
import 'package:oflite/modules/pdf/pdf_edit/presenter/pdf_edit_view_model.dart';

/// Registra as dependências do módulo PDF.
void registerPdfDependencies(GetIt sl) {
  sl.registerLazySingleton<PdfRemoteDataSource>(
    () => PdfRemoteDataSource(),
  );
  // PdfRepositoryImpl depende também de BudgetRemoteDataSource (já registrado).
  sl.registerLazySingleton<PdfRepository>(
    () => PdfRepositoryImpl(
      sl<PdfRemoteDataSource>(),
      sl<BudgetRemoteDataSource>(),
    ),
  );

  // Usecases (stateless)
  sl.registerLazySingleton<PdfGenerateUseCase>(
    () => PdfGenerateUseCase(sl<ConvertCoinRepository>()),
  );
  sl.registerLazySingleton<PdfGenerateReceiptUseCase>(
    () => PdfGenerateReceiptUseCase(sl<ConvertCoinRepository>()),
  );

  // ViewModels (Factory — sem parâmetros required no construtor)
  sl.registerFactory<PdfEditViewModel>(
    () => PdfEditViewModel(
      pdfRepository: sl<PdfRepository>(),
      userRepository: sl<UserRepository>(),
      displayAlertRepository: sl<DisplayAlertRepository>(),
      loadingEventRepository: sl<LoadingEventRepository>(),
    ),
  );
  sl.registerFactory<PdfBudgetViewModel>(
    () => PdfBudgetViewModel(
      pdfRepository: sl<PdfRepository>(),
      displayAlertRepository: sl<DisplayAlertRepository>(),
      convertCoinRepository: sl<ConvertCoinRepository>(),
      pdfGenerateUseCase: sl<PdfGenerateUseCase>(),
    ),
  );
}
