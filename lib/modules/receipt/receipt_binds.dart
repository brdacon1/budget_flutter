import 'package:get_it/get_it.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_payment_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/receipt/data/repository/receipt_ledger_repository_impl.dart';
import 'package:oflite/modules/receipt/data/repository/receipt_payment_repository_impl.dart';
import 'package:oflite/modules/receipt/data/repository/receipt_repository_impl.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_ledger_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_payment_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/modules/receipt/domain/usecase/create_receipt_for_budget_usecase.dart';
import 'package:oflite/modules/receipt/domain/usecase/get_receipts_report_usecase.dart';
import 'package:oflite/modules/receipt/domain/usecase/list_receipts_by_budget_usecase.dart';

void registerReceiptDependencies(GetIt sl) {
  sl.registerLazySingleton<ReceiptRemoteDatasource>(
    () => ReceiptRemoteDatasource(),
  );
  sl.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(
      sl<ReceiptRemoteDatasource>(),
      sl<ReceiptPaymentRemoteDatasource>(),
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
  sl.registerLazySingleton<CreateReceiptForBudgetUsecase>(
    () => CreateReceiptForBudgetUsecase(
      sl<ReceiptRepository>(),
      sl<ReceiptPaymentRepository>(),
      sl<ReceiptLedgerRepository>(),
    ),
  );
  sl.registerLazySingleton<ListReceiptsByBudgetUsecase>(
    () => ListReceiptsByBudgetUsecase(
      sl<ReceiptRepository>(),
      sl<ReceiptPaymentRepository>(),
    ),
  );
  sl.registerLazySingleton<ReceiptLedgerRepository>(
    () => ReceiptLedgerRepositoryImpl(
      sl<ReceiptRemoteDatasource>(),
      sl<ReceiptPaymentRemoteDatasource>(),
      sl<UserRepository>(),
    ),
  );
  // BudgetRepository resolvido na 1ª chamada (lazy), independe da ordem dos binds.
  sl.registerLazySingleton<GetReceiptsReportUsecase>(
    () => GetReceiptsReportUsecase(
      sl<ReceiptLedgerRepository>(),
      sl<BudgetRepository>(),
    ),
  );
}
