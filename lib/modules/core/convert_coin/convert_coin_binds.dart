import 'package:get_it/get_it.dart';

import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/convert_coin/data/repository/convert_coin_repository_impl.dart';

/// Registra o serviço de formatação/conversão de moeda.
void registerConvertCoinDependencies(GetIt sl) {
  sl.registerLazySingleton<ConvertCoinRepository>(
    () => ConvertCoinRepositoryImpl(),
  );
}
