import 'package:get_it/get_it.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_payment_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/repository/receipt_payment_repository_impl.dart';
import 'package:oflite/modules/receipt/data/repository/receipt_repository_impl.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_payment_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';

void registerReceiptDependencies(GetIt sl) {
  sl.registerLazySingleton<ReceiptRemoteDatasource>(
    () => ReceiptRemoteDatasource(),
  );
  sl.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(
      sl<ReceiptRemoteDatasource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerLazySingleton<ReceiptPaymentRemoteDatasource>(
    () => ReceiptPaymentRemoteDatasource(),
  );
  sl.registerLazySingleton<ReceiptPaymentRepository>(
    () => BudgetPaymentRepositoryImpl(
      sl<ReceiptPaymentRemoteDatasource>(),
      sl<ReceiptRemoteDatasource>(),
      sl<UserRepository>(),
    ),
  );
}
