import 'package:get_it/get_it.dart';
import 'package:oflite/modules/login/data/datasource/user_remote_datasource.dart';
import 'package:oflite/modules/login/data/repository/user_repository_impl.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';

void registerLoginDependencies(GetIt sl) {
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSource(),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl<UserRemoteDataSource>()),
  );
}
