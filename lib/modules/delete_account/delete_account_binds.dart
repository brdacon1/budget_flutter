import 'package:get_it/get_it.dart';
import 'package:oflite/modules/delete_account/data/datasource/delete_account_remote_datasource.dart';
import 'package:oflite/modules/delete_account/data/repository/delete_account_repository_impl.dart';
import 'package:oflite/modules/delete_account/domain/repository/delete_account_repository.dart';
import 'package:oflite/modules/delete_account/presenter/delete_account_view_model.dart';

void registerDeleteAccountDependencies(GetIt sl) {
  sl.registerLazySingleton<DeleteAccountRemoteDataSource>(
    () => DeleteAccountRemoteDataSource(),
  );
  sl.registerLazySingleton<DeleteAccountRepository>(
    () => DeleteAccountRepositoryImpl(sl<DeleteAccountRemoteDataSource>()),
  );

  // ViewModel sempre factory
  sl.registerFactory<DeleteAccountViewModel>(
    () => DeleteAccountViewModel(sl<DeleteAccountRepository>()),
  );
}
