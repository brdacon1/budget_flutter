import 'package:get_it/get_it.dart';
import 'package:oflite/modules/core/crashlytics/data/datasource/crashlytics_remote_datasource.dart';
import 'package:oflite/modules/core/crashlytics/data/repository/crashlytics_repository_impl.dart';
import 'package:oflite/modules/core/crashlytics/domain/repository/crashlytics_repository.dart';

/// Registra o serviço de relatório de crashes (Firebase Crashlytics).
void registerCrashlyticsDependencies(GetIt sl) {
  sl.registerLazySingleton<CrashlyticsRemoteDataSource>(
    () => CrashlyticsRemoteDataSource(),
  );
  sl.registerLazySingleton<CrashlyticsRepository>(
    () => CrashlyticsRepositoryImpl(sl<CrashlyticsRemoteDataSource>()),
  );
}
