import 'package:intl/intl.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_ledger_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_payment_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Cria um recibo vinculado a um orçamento e, se [amount] vier, já registra o
/// pagamento dentro dele — mesmo formato gravado pelas telas de recibo.
///
/// Os repositórios guardam `budgetId`/`receiptId` como estado compartilhado
/// com as telas: o valor anterior é restaurado ao final para não bagunçar uma
/// tela de recibos aberta por baixo do chat.
class CreateReceiptForBudgetUsecase {
  final ReceiptRepository _receiptRepo;
  final ReceiptPaymentRepository _paymentRepo;

  /// Cache do relatório de recibos: descartado após gravar.
  final ReceiptLedgerRepository? _ledger;

  const CreateReceiptForBudgetUsecase(
    this._receiptRepo,
    this._paymentRepo, [
    this._ledger,
  ]);

  Future<Result<Receipt>> call({
    required String budgetId,
    required String description,
    double? amount,
    String? method,
    DateTime? now,
  }) async {
    if (description.trim().isEmpty) {
      return Result.error(Exception('description_required'));
    }
    if (amount != null && amount <= 0) {
      return Result.error(Exception('amount_must_be_positive'));
    }

    final date = now ?? DateTime.now();
    final receipt = Receipt(
      id: date.millisecondsSinceEpoch.toString(),
      data: DateFormat('dd/MM/yyyy').format(date),
      descricao: description.trim(),
      valorTotal: 0,
    );

    final prevBudget = _receiptRepo.budgetId;
    final prevPayBudget = _paymentRepo.budgetId;
    final prevPayReceipt = _paymentRepo.receiptId;
    try {
      _receiptRepo.budgetId = budgetId;
      final saved = await _receiptRepo.saveReceipt(receipt);
      if (saved case Error(:final error)) return Result.error(error);

      if (amount != null) {
        _paymentRepo.budgetId = budgetId;
        _paymentRepo.receiptId = receipt.id;
        final paid = await _paymentRepo.savePayment(
          PaymentCustomer(
            method: method,
            description: description.trim(),
            price: amount,
          ),
        );
        if (paid case Error(:final error)) return Result.error(error);
      }
      return Result.ok(receipt);
    } finally {
      _ledger?.invalidate();
      _receiptRepo.budgetId = prevBudget;
      _paymentRepo.budgetId = prevPayBudget;
      _paymentRepo.receiptId = prevPayReceipt;
    }
  }
}
