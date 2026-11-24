import 'package:get_it/get_it.dart';
import 'package:oflite/modules/auth/data/datasource/auth_remote_datasource.dart';
import 'package:oflite/modules/auth/data/datasource/user_remote_datasource.dart';
import 'package:oflite/modules/auth/data/repository/auth_repository_impl.dart';
import 'package:oflite/modules/auth/domain/repository/auth_repository.dart';
import 'package:oflite/modules/auth/data/repository/user_repository_impl.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/load_user_session_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/register_email_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/restore_session_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/sign_in_email_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/sign_in_social_usecase.dart';
import 'package:oflite/modules/core/crashlytics/domain/repository/crashlytics_repository.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/product/domain/usecase/create_sample_product_usecase.dart';
import 'package:oflite/modules/auth/presenter/login/login_view_model.dart';
import 'package:oflite/modules/auth/presenter/singup/singup_view_model.dart';

void registerAuthDependencies(GetIt sl) {
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource());
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );
  sl.registerLazySingleton<UserRemoteDataSource>(() => UserRemoteDataSource());
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl<UserRemoteDataSource>()),
  );

  // UseCases
  sl.registerLazySingleton<GetAccessStatusUseCase>(
    () => GetAccessStatusUseCase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<LoadUserSessionUseCase>(
    () => LoadUserSessionUseCase(
      sl<UserRepository>(),
      sl<NotificationRepository>(),
      sl<CrashlyticsRepository>(),
      sl<InAppPurchaseRepository>(),
    ),
  );
  sl.registerLazySingleton<SignInEmailUseCase>(
    () => SignInEmailUseCase(
      sl<AuthRepository>(),
      sl<UserRepository>(),
      sl<LoadUserSessionUseCase>(),
    ),
  );
  sl.registerLazySingleton<SignInSocialUseCase>(
    () => SignInSocialUseCase(
      sl<AuthRepository>(),
      sl<UserRepository>(),
      sl<PdfRepository>(),
      sl<LoadUserSessionUseCase>(),
      sl<CreateSampleProductUseCase>(),
    ),
  );
  sl.registerLazySingleton<RegisterEmailUseCase>(
    () => RegisterEmailUseCase(
      sl<AuthRepository>(),
      sl<UserRepository>(),
      sl<PdfRepository>(),
      sl<LoadUserSessionUseCase>(),
      sl<CreateSampleProductUseCase>(),
    ),
  );
  sl.registerLazySingleton<RestoreSessionUseCase>(
    () => RestoreSessionUseCase(
      sl<AuthRepository>(),
      sl<UserRepository>(),
      sl<LoadUserSessionUseCase>(),
      sl<SignInEmailUseCase>(),
    ),
  );

  // ViewModels
  sl.registerFactory<LoginViewModel>(() => LoginViewModel());
  sl.registerFactory<SingUpViewModel>(() => SingUpViewModel());
}
