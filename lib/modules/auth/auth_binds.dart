import 'package:get_it/get_it.dart';
import 'package:oflite/modules/auth/data/datasource/user_remote_datasource.dart';
import 'package:oflite/modules/auth/data/repository/user_repository_impl.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/presenter/login/login_view_model.dart';
import 'package:oflite/modules/auth/presenter/singup/singup_view_model.dart';

void registerAuthDependencies(GetIt sl) {
  sl.registerLazySingleton<UserRemoteDataSource>(() => UserRemoteDataSource());
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl<UserRemoteDataSource>()),
  );

  // ViewModels
  sl.registerFactory<LoginViewModel>(() => LoginViewModel());
  sl.registerFactory<SingUpViewModel>(() => SingUpViewModel());
}
