import 'package:get_it/get_it.dart';

import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/modules/core/share_link/data/datasource/share_link_datasource.dart';
import 'package:oflite/modules/core/share_link/data/repository/share_link_repository_impl.dart';

/// Registra o serviço de geração de link público do orçamento.
void registerShareLinkDependencies(GetIt sl) {
  sl.registerLazySingleton<ShareLinkDataSource>(
    () => ShareLinkDataSource(),
  );
  sl.registerLazySingleton<ShareLinkRepository>(
    () => ShareLinkRepositoryImpl(sl<ShareLinkDataSource>()),
  );
}
