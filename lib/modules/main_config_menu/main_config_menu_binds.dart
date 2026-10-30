import 'package:get_it/get_it.dart';
import 'package:oflite/modules/main_config_menu/presenter/main_config_menu_view_model.dart';

/// Registra as dependências do módulo MainConfigMenu.
void registerMainConfigMenuDependencies(GetIt sl) {
  sl.registerFactory<MainConfigMenuViewModel>(() => MainConfigMenuViewModel());
}
