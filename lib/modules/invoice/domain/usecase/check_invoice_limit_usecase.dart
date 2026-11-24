import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_limits.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// O orçamento comporta mais [adding] notas fiscais? (máx. 15).
class CheckInvoiceLimitUsecase {
  final InvoiceRepository _repo;

  const CheckInvoiceLimitUsecase(this._repo);

  Future<Result<({int count, bool fits})>> call(
    String budgetId, {
    required int adding,
  }) async {
    final res = await _repo.countInvoices(budgetId);
    return switch (res) {
      Ok(:final value) => Result.ok((
        count: value,
        fits: value + adding <= PaymentProofLimits.maxPerBudget,
      )),
      Error(:final error) => Result.error(error),
    };
  }
}
