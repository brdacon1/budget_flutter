import 'package:get_it/get_it.dart';
import 'package:oflite/modules/terms_conditions/presenter/terms_conditions_view_model.dart';

/// Registra as dependências do módulo TermsConditions.
void registerTermsConditionsDependencies(GetIt sl) {
  sl.registerFactory<TermsConditionsViewModel>(() => TermsConditionsViewModel());
}
