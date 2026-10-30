import 'package:get_it/get_it.dart';

import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/core/loading_event/data/repository/loading_event_repository_impl.dart';

/// Registra o serviço de loading (dialog com spinner).
void registerLoadingEventDependencies(GetIt sl) {
  sl.registerLazySingleton<LoadingEventRepository>(
    () => LoadingEventRepositoryImpl(),
  );
}
