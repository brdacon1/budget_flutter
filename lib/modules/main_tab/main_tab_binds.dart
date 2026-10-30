import 'package:get_it/get_it.dart';
import 'package:oflite/modules/main_tab/presenter/main_tab_view_model.dart';

/// Registra as dependências do módulo MainTab.
void registerMainTabDependencies(GetIt sl) {
  sl.registerFactory<MainTabViewModel>(() => MainTabViewModel());
}
