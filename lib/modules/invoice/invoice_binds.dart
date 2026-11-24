import 'package:get_it/get_it.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/invoice/data/datasource/invoice_remote_datasource.dart';
import 'package:oflite/modules/invoice/data/datasource/invoice_storage_datasource.dart';
import 'package:oflite/modules/invoice/data/repository/invoice_repository_impl.dart';
import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/modules/invoice/domain/usecase/check_invoice_limit_usecase.dart';
import 'package:oflite/modules/invoice/domain/usecase/create_invoice_usecase.dart';
import 'package:oflite/modules/invoice/domain/usecase/delete_invoice_usecase.dart';
import 'package:oflite/modules/invoice/domain/usecase/list_invoices_usecase.dart';
import 'package:oflite/modules/payment_proof/data/datasource/proof_file_local_datasource.dart';

void registerInvoiceDependencies(GetIt sl) {
  sl.registerLazySingleton(() => InvoiceRemoteDatasource());
  sl.registerLazySingleton(() => InvoiceStorageDatasource());
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(
      sl<InvoiceRemoteDatasource>(),
      sl<InvoiceStorageDatasource>(),
      sl<ProofFileLocalDatasource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => CheckInvoiceLimitUsecase(sl<InvoiceRepository>()),
  );
  sl.registerLazySingleton(() => CreateInvoiceUsecase(sl<InvoiceRepository>()));
  sl.registerLazySingleton(() => ListInvoicesUsecase(sl<InvoiceRepository>()));
  sl.registerLazySingleton(() => DeleteInvoiceUsecase(sl<InvoiceRepository>()));
}
