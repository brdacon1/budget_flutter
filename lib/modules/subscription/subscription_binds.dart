import 'package:get_it/get_it.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view_model.dart';

/// Registra as dependências do módulo Subscription.
void registerSubscriptionDependencies(GetIt sl) {
  sl.registerFactory<SubscriptionViewModel>(() => SubscriptionViewModel());
}
