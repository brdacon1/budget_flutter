import 'package:get_it/get_it.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/receipt/data/datasource/budget_payment_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/repository/budget_payment_repository_impl.dart';
import 'package:oflite/modules/receipt/data/repository/receipt_repository_impl.dart';
import 'package:oflite/modules/receipt/domain/repository/budget_payment_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';

void registerReceiptDependencies(GetIt sl) {
  sl.registerLazySingleton<ReceiptRemoteDataSource>(
    () => ReceiptRemoteDataSource(),
  );
  sl.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(
      sl<ReceiptRemoteDataSource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerLazySingleton<BudgetPaymentRemoteDatasource>(
    () => BudgetPaymentRemoteDatasource(),
  );
  sl.registerLazySingleton<BudgetPaymentRepository>(
    () => BudgetPaymentRepositoryImpl(
      sl<BudgetPaymentRemoteDatasource>(),
      sl<ReceiptRemoteDataSource>(),
      sl<UserRepository>(),
    ),
  );
}
