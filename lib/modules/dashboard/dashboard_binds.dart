import 'package:get_it/get_it.dart';
import 'package:oflite/modules/dashboard/presenter/dashboard_view_model.dart';

/// Registra as dependências do módulo Dashboard.
void registerDashboardDependencies(GetIt sl) {
  sl.registerFactory<DashboardViewModel>(() => DashboardViewModel());
}
