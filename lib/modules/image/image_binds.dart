import 'package:get_it/get_it.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/image/data/datasource/image_logo_remote_datasource.dart';
import 'package:oflite/modules/image/data/repository/image_logo_repository_impl.dart';
import 'package:oflite/modules/image/domain/repository/image_logo_repository.dart';
import 'package:oflite/modules/image/domain/usecase/crop_logo_usecase.dart';
import 'package:oflite/modules/image/domain/usecase/delete_logo_usecase.dart';
import 'package:oflite/modules/image/domain/usecase/upload_logo_usecase.dart';
import 'package:oflite/modules/image/presenter/image_edit_view_model.dart';

/// Registra as dependências do módulo Image.
void registerImageDependencies(GetIt sl) {
  sl.registerLazySingleton(() => ImageLogoRemoteDatasource());
  sl.registerLazySingleton<ImageLogoRepository>(
    () => ImageLogoRepositoryImpl(sl<ImageLogoRemoteDatasource>()),
  );
  sl.registerLazySingleton(() => CropLogoUsecase(sl<ImageLogoRepository>()));
  sl.registerLazySingleton(
    () => UploadLogoUsecase(sl<ImageLogoRepository>(), sl<UserRepository>()),
  );
  sl.registerLazySingleton(() => DeleteLogoUsecase(sl<ImageLogoRepository>()));
  sl.registerFactory<ImageEditViewModel>(
    () => ImageEditViewModel(
      sl<ImageLogoRepository>(),
      sl<CropLogoUsecase>(),
      sl<UploadLogoUsecase>(),
      sl<DeleteLogoUsecase>(),
    ),
  );
}
