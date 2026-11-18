import 'package:get_it/get_it.dart';
import 'package:oflite/modules/core/app_check/data/datasource/app_check_remote_datasource.dart';
import 'package:oflite/modules/core/app_check/data/repository/app_check_repository_impl.dart';
import 'package:oflite/modules/core/app_check/domain/repository/app_check_repository.dart';

/// Registra o Firebase App Check.
void registerAppCheckDependencies(GetIt sl) {
  sl.registerLazySingleton<AppCheckRemoteDataSource>(
    () => AppCheckRemoteDataSource(),
  );
  sl.registerLazySingleton<AppCheckRepository>(
    () => AppCheckRepositoryImpl(sl<AppCheckRemoteDataSource>()),
  );
}
