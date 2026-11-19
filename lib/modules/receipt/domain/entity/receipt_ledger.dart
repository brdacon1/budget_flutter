import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';

/// Recibo com o orçamento dono, a data de criação e os pagamentos.
///
/// `issued` = `VALORTOTAL` do recibo; `paid` = soma de `PRECO` dos pagamentos.
/// Base comum do relatório de recibos (Fase 9) e do saldo do orçamento
/// (Fase 10): "quanto foi pago" é calculado só aqui.
class LedgerReceipt {
  final Receipt receipt;
  final String budgetId;
  final DateTime createdAt;
  final List<PaymentCustomer> payments;
  final double issued;
  final double paid;

  LedgerReceipt({
    required this.receipt,
    required this.budgetId,
    required this.createdAt,
    this.payments = const [],
  }) : issued = receipt.valorTotal ?? 0,
       paid = payments.fold<double>(0, (s, p) => s + (p.price ?? 0));
}

/// Todos os recibos do usuário, agrupados por orçamento.
class ReceiptLedger {
  final Map<String, List<LedgerReceipt>> byBudget;

  const ReceiptLedger(this.byBudget);

  Iterable<LedgerReceipt> get all => byBudget.values.expand((e) => e);

  /// Total pago (soma dos pagamentos) de um orçamento.
  double paidFor(String budgetId) =>
      (byBudget[budgetId] ?? const []).fold(0, (s, r) => s + r.paid);
}
