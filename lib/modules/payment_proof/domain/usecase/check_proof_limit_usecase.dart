import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_limits.dart';
import 'package:oflite/modules/payment_proof/domain/repository/payment_proof_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// R3: o orçamento comporta mais [adding] comprovantes? (máx. 15).
/// Devolve quantos já existem e se cabe.
class CheckProofLimitUsecase {
  final PaymentProofRepository _repo;

  const CheckProofLimitUsecase(this._repo);

  Future<Result<({int count, bool fits})>> call(
    String budgetId, {
    required int adding,
  }) async {
    final res = await _repo.countProofs(budgetId);
    return switch (res) {
      Ok(:final value) => Result.ok((
        count: value,
        fits: value + adding <= PaymentProofLimits.maxPerBudget,
      )),
      Error(:final error) => Result.error(error),
    };
  }
}
