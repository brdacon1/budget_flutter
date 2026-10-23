import 'package:get_it/get_it.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/repository/receipt_repository_impl.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';

void registerReceiptDependencies(GetIt sl) {
  sl.registerLazySingleton<ReceiptRemoteDataSource>(
    () => ReceiptRemoteDataSource(),
  );
  sl.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(sl<ReceiptRemoteDataSource>()),
  );
}
