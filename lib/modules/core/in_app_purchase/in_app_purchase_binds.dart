import 'package:get_it/get_it.dart';

import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'package:oflite/modules/core/in_app_purchase/data/repository/in_app_purchase_repository_impl.dart';

/// Registra o serviço de compras in-app (assinaturas).
void registerInAppPurchaseDependencies(GetIt sl) {
  sl.registerLazySingleton<InAppPurchaseRepository>(
    () => InAppPurchaseRepositoryImpl(),
  );
}
