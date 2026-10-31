import 'package:get_it/get_it.dart';

import 'package:oflite/modules/core/notification/data/datasource/notification_remote_datasource.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/modules/core/notification/data/repository/notification_repository_impl.dart';

/// Registra o serviço de notificações push (FCM + local).
void registerNotificationDependencies(GetIt sl) {
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSource(),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl<NotificationRemoteDataSource>()),
  );
}
