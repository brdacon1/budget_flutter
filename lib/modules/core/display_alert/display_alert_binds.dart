import 'package:get_it/get_it.dart';

import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/display_alert/data/repository/display_alert_repository_impl.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';

/// Registra o serviço de alertas e modais.
///
/// Depende de [LoadingEventRepository] (já registrado em
/// `registerLoadingEventDependencies`).
void registerDisplayAlertDependencies(GetIt sl) {
  sl.registerLazySingleton<DisplayAlertRepository>(
    () => DisplayAlertRepositoryImpl(
      loadingEvent: sl<LoadingEventRepository>(),
    ),
  );
}
