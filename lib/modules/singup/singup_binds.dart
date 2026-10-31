import 'package:get_it/get_it.dart';
import 'package:oflite/modules/singup/presenter/singup_view_model.dart';

/// Registra as dependências do módulo SingUp.
void registerSingupDependencies(GetIt sl) {
  sl.registerFactory<SingUpViewModel>(() => SingUpViewModel());
}
