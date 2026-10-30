import 'package:get_it/get_it.dart';

import 'package:oflite/modules/core/cep/domain/repository/cep_repository.dart';
import 'package:oflite/modules/core/cep/data/datasource/cep_remote_datasource.dart';
import 'package:oflite/modules/core/cep/data/repository/cep_repository_impl.dart';

/// Registra o serviço de consulta de CEP.
void registerCepDependencies(GetIt sl) {
  sl.registerLazySingleton<CepRemoteDataSource>(
    () => CepRemoteDataSource(),
  );
  sl.registerLazySingleton<CepRepository>(
    () => CepRepositoryImpl(sl<CepRemoteDataSource>()),
  );
}
