import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/receipt/data/repository/receipt_ledger_repository_impl.dart';

void main() {
  test('junta pagamentos ao recibo pelo caminho e ignora órfãos', () {
    final ledger = ReceiptLedgerRepositoryImpl.build(
      [
        {
          'id': '1763300000000',
          'budgetId': 'b1',
          'VALORTOTAL': 100,
          'DATA': '16/11/2026',
        },
        {'id': '1763300000001', 'budgetId': 'b2', 'VALORTOTAL': 50},
        {'id': 'legado', 'budgetId': 'b2', 'DATA': '05/10/2026'},
        {'id': 'sem-data', 'budgetId': 'b2'},
      ],
      [
        {'budgetId': 'b1', 'receiptId': '1763300000000', 'PRECO': 30},
        {'budgetId': 'b1', 'receiptId': '1763300000000', 'PRECO': 20.5},
        {'budgetId': 'b9', 'receiptId': 'x', 'PRECO': 999},
      ],
    );
    expect(ledger.paidFor('b1'), 50.5);
    expect(ledger.paidFor('b2'), 0);
    expect(ledger.all.length, 3);
    final legacy = ledger.byBudget['b2']!.firstWhere(
      (r) => r.receipt.id == 'legado',
    );
    expect(legacy.createdAt, DateTime(2026, 10, 5));
    expect(ledger.byBudget['b1']!.single.issued, 100);
  });
}
