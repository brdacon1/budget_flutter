import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_payment_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Recibo com o total pago (soma dos pagamentos).
typedef ReceiptWithTotal = ({Receipt receipt, double paid});

/// Lista os recibos de um orçamento com o total pago em cada um.
/// Restaura o estado compartilhado dos repositórios ao final.
class ListReceiptsByBudgetUsecase {
  final ReceiptRepository _receiptRepo;
  final ReceiptPaymentRepository _paymentRepo;

  const ListReceiptsByBudgetUsecase(this._receiptRepo, this._paymentRepo);

  Future<Result<List<ReceiptWithTotal>>> call(String budgetId) async {
    final prevBudget = _receiptRepo.budgetId;
    final prevPayBudget = _paymentRepo.budgetId;
    final prevPayReceipt = _paymentRepo.receiptId;
    try {
      _receiptRepo.budgetId = budgetId;
      final fetched = await _receiptRepo.fetchReceipts(forceRefresh: true);
      if (fetched case Error(:final error)) return Result.error(error);

      final out = <ReceiptWithTotal>[];
      _paymentRepo.budgetId = budgetId;
      for (final r in (fetched as Ok<List<Receipt>>).value) {
        _paymentRepo.receiptId = r.id;
        final pays = await _paymentRepo.fetchPayments(r, forceRefresh: true);
        final paid = switch (pays) {
          Ok(:final value) => value.fold<double>(
            0,
            (sum, PaymentCustomer p) => sum + (p.price ?? 0),
          ),
          Error() => 0.0,
        };
        out.add((receipt: r, paid: paid));
      }
      return Result.ok(out);
    } finally {
      _receiptRepo.budgetId = prevBudget;
      _paymentRepo.budgetId = prevPayBudget;
      _paymentRepo.receiptId = prevPayReceipt;
    }
  }
}
