import 'package:get_it/get_it.dart';
import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/pdf/data/datasource/pdf_remote_datasource.dart';
import 'package:oflite/modules/pdf/data/repository/pdf_repository_impl.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/pdf_budget/presenter/pdf_budget_view_model.dart';
import 'package:oflite/modules/pdf/pdf_edit/presenter/pdf_edit_view_model.dart';

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

  // ViewModels
  sl.registerFactory<PdfEditViewModel>(() => PdfEditViewModel());
  sl.registerFactory<PdfBudgetViewModel>(() => PdfBudgetViewModel());
}
