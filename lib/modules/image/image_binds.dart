import 'package:get_it/get_it.dart';
import 'package:oflite/modules/image/presenter/image_edit_view_model.dart';

/// Registra as dependências do módulo Image.
void registerImageDependencies(GetIt sl) {
  sl.registerFactory<ImageEditViewModel>(() => ImageEditViewModel());
}
