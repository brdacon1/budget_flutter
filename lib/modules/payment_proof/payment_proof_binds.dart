import 'package:get_it/get_it.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/payment_proof/data/datasource/payment_proof_remote_datasource.dart';
import 'package:oflite/modules/payment_proof/data/datasource/payment_proof_storage_datasource.dart';
import 'package:oflite/modules/payment_proof/data/datasource/proof_file_local_datasource.dart';
import 'package:oflite/modules/payment_proof/data/repository/payment_proof_repository_impl.dart';
import 'package:oflite/modules/payment_proof/domain/repository/payment_proof_repository.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/check_proof_limit_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/create_payment_proof_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/delete_payment_proof_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/list_payment_proofs_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/parse_money_input_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';

void registerPaymentProofDependencies(GetIt sl) {
  sl.registerLazySingleton(() => PaymentProofRemoteDatasource());
  sl.registerLazySingleton(() => PaymentProofStorageDatasource());
  sl.registerLazySingleton(() => ProofFileLocalDatasource());
  sl.registerLazySingleton<PaymentProofRepository>(
    () => PaymentProofRepositoryImpl(
      sl<PaymentProofRemoteDatasource>(),
      sl<PaymentProofStorageDatasource>(),
      sl<ProofFileLocalDatasource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => ValidateProofAttachmentsUsecase(sl<PaymentProofRepository>()),
  );
  sl.registerLazySingleton(
    () => CheckProofLimitUsecase(sl<PaymentProofRepository>()),
  );
  sl.registerLazySingleton(
    () => CreatePaymentProofUsecase(sl<PaymentProofRepository>()),
  );
  sl.registerLazySingleton(
    () => ListPaymentProofsUsecase(sl<PaymentProofRepository>()),
  );
  sl.registerLazySingleton(
    () => DeletePaymentProofUsecase(sl<PaymentProofRepository>()),
  );
  sl.registerLazySingleton(() => const ParseMoneyInputUsecase());
}
