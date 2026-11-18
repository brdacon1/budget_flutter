import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_payment_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/modules/receipt/domain/usecase/create_receipt_for_budget_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeReceiptRepo extends ChangeNotifier implements ReceiptRepository {
  @override
  String? budgetId = 'tela-aberta';
  String? savedOnBudget;
  Receipt? saved;

  @override
  Future<Result<void>> saveReceipt(Receipt receipt) async {
    savedOnBudget = budgetId;
    saved = receipt;
    return const Result.ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepo extends ChangeNotifier
    implements ReceiptPaymentRepository {
  @override
  String? budgetId;
  @override
  String? receiptId;
  String? savedOn;
  PaymentCustomer? saved;

  @override
  Future<Result<void>> savePayment(PaymentCustomer payment) async {
    savedOn = '$budgetId/$receiptId';
    saved = payment;
    return const Result.ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'grava recibo + pagamento no orçamento certo e restaura o estado',
    () async {
      final receipts = _FakeReceiptRepo();
      final payments = _FakePaymentRepo();
      final result = await CreateReceiptForBudgetUsecase(receipts, payments)(
        budgetId: 'b1',
        description: ' Entrada ',
        amount: 500,
        method: 'PIX',
        now: DateTime(2026, 11, 18),
      );

      final receipt = (result as Ok<Receipt>).value;
      expect(receipts.savedOnBudget, 'b1');
      expect(receipt.descricao, 'Entrada');
      expect(receipt.data, '18/11/2026');
      expect(payments.savedOn, 'b1/${receipt.id}');
      expect(payments.saved?.price, 500);
      expect(payments.saved?.method, 'PIX');
      // Estado compartilhado com as telas volta ao que era.
      expect(receipts.budgetId, 'tela-aberta');
      expect(payments.budgetId, isNull);
      expect(payments.receiptId, isNull);
    },
  );

  test('sem valor não cria pagamento; valor <= 0 é recusado', () async {
    final receipts = _FakeReceiptRepo();
    final payments = _FakePaymentRepo();
    final usecase = CreateReceiptForBudgetUsecase(receipts, payments);

    await usecase(budgetId: 'b1', description: 'Recibo');
    expect(receipts.saved, isNotNull);
    expect(payments.saved, isNull);

    final invalid = await usecase(budgetId: 'b1', description: 'x', amount: 0);
    expect(invalid, isA<Error<Receipt>>());
  });
}
