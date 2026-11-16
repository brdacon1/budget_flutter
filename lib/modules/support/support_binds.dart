import 'package:get_it/get_it.dart';
import 'package:oflite/modules/support/presenter/support_view_model.dart';

void registerSupportDependencies(GetIt sl) {
  // ViewModel sempre factory
  sl.registerFactory<SupportViewModel>(() => SupportViewModel());
}
