import 'package:get_it/get_it.dart';
import 'package:oflite/modules/legal/presenter/legal_view_model.dart';

void registerLegalDependencies(GetIt sl) {
  // ViewModel sempre factory
  sl.registerFactory<LegalViewModel>(() => LegalViewModel());
}
