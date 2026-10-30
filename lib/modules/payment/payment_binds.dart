import 'package:get_it/get_it.dart';
import 'package:oflite/modules/payment/data/datasource/payment_remote_datasource.dart';
import 'package:oflite/modules/payment/data/repository/payment_repository_impl.dart';
import 'package:oflite/modules/payment/domain/repository/payment_repository.dart';
import 'package:oflite/modules/payment/payment_creator/presenter/payment_creator_view_model.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';

void registerPaymentDependencies(GetIt sl) {
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSource(),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(
      sl<PaymentRemoteDataSource>(),
      sl<ReceiptRemoteDataSource>(),
    ),
  );

  // ViewModels
  sl.registerFactory<PaymentCreatorViewModel>(() => PaymentCreatorViewModel());
}
