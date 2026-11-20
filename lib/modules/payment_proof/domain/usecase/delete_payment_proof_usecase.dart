import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/repository/payment_proof_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Apaga o documento e o arquivo do Storage (libera vaga no limite de 15).
class DeletePaymentProofUsecase {
  final PaymentProofRepository _repo;

  const DeletePaymentProofUsecase(this._repo);

  Future<Result<void>> call(String budgetId, PaymentProof proof) =>
      _repo.deleteProof(budgetId, proof);
}
