import 'package:get_it/get_it.dart';

import 'package:oflite/modules/core/map_launcher/data/datasource/map_launcher_datasource.dart';
import 'package:oflite/modules/core/map_launcher/data/repository/map_launcher_repository_impl.dart';
import 'package:oflite/modules/core/map_launcher/domain/repository/map_launcher_repository.dart';

/// Registra o serviço que abre endereços nos apps de mapa.
void registerMapLauncherDependencies(GetIt sl) {
  sl.registerLazySingleton<MapLauncherDataSource>(
    () => MapLauncherDataSource(),
  );
  sl.registerLazySingleton<MapLauncherRepository>(
    () => MapLauncherRepositoryImpl(sl<MapLauncherDataSource>()),
  );
}
