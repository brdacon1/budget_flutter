import 'package:get_it/get_it.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_dashboard_month_summary_usecase.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_receipts_comparison_usecase.dart';
import 'package:oflite/modules/home/presenter/home_view_model.dart';

/// Registra as dependências do módulo Home.
void registerHomeDependencies(GetIt sl) {
  sl.registerFactory<HomeViewModel>(
    () => HomeViewModel(
      sl<GetDashboardMonthSummaryUsecase>(),
      sl<GetReceiptsComparisonUsecase>(),
    ),
  );
}
