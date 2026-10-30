import 'package:get_it/get_it.dart';

import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/core/ads/data/repository/ads_repository_impl.dart';

/// Registra o serviço de anúncios AdMob.
void registerAdsDependencies(GetIt sl) {
  sl.registerLazySingleton<AdsRepository>(
    () => AdsRepositoryImpl(),
  );
}
