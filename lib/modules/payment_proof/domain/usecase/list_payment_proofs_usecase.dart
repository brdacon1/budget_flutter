import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/repository/payment_proof_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Comprovantes do orçamento + resumo do rodapé.
typedef PaymentProofList = ({List<PaymentProof> proofs, double total});

/// Comprovantes do orçamento, mais recente primeiro, com a soma dos valores
/// (a soma é regra de negócio: fica aqui, não no VM).
class ListPaymentProofsUsecase {
  final PaymentProofRepository _repo;

  const ListPaymentProofsUsecase(this._repo);

  static double totalOf(Iterable<PaymentProof> proofs) =>
      proofs.fold(0.0, (sum, p) => sum + (p.value ?? 0));

  Future<Result<PaymentProofList>> call(String budgetId) async {
    final res = await _repo.fetchProofs(budgetId);
    return switch (res) {
      Ok(:final value) => Result.ok((
        proofs: [...value]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        total: totalOf(value),
      )),
      Error(:final error) => Result.error(error),
    };
  }
}
