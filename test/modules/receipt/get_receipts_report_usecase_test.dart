import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/domain/entity/receipt_ledger.dart';
import 'package:oflite/modules/receipt/domain/entity/receipts_report.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_ledger_repository.dart';
import 'package:oflite/modules/receipt/domain/usecase/get_receipts_report_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _Ledger implements ReceiptLedgerRepository {
  _Ledger(this.items);
  final List<LedgerReceipt> items;

  @override
  Future<Result<ReceiptLedger>> fetchLedger({bool forceRefresh = false}) async {
    final map = <String, List<LedgerReceipt>>{};
    for (final r in items) {
      map.putIfAbsent(r.budgetId, () => []).add(r);
    }
    return Result.ok(ReceiptLedger(map));
  }

  @override
  void invalidate() {}
}

class _Budgets extends ChangeNotifier implements BudgetRepository {
  @override
  Future<Result<CustomerInfo>> getBudgetById(String id) async =>
      Result.ok(CustomerInfo(id: id, customerName: 'Cliente $id'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LedgerReceipt _r(
  String budget,
  DateTime at, {
  double issued = 0,
  List<double> pays = const [],
}) => LedgerReceipt(
  receipt: Receipt(id: '${at.millisecondsSinceEpoch}', valorTotal: issued),
  budgetId: budget,
  createdAt: at,
  payments: [for (final p in pays) PaymentCustomer(price: p)],
);

void main() {
  // Semana de seg 16/11/2026 a dom 22/11/2026.
  final items = [
    _r('a', DateTime(2026, 11, 16, 0, 0), issued: 100, pays: [50, 30]),
    _r('a', DateTime(2026, 11, 22, 23, 59, 59), issued: 200, pays: [200]),
    _r('b', DateTime(2026, 11, 18), issued: 0),
    _r('b', DateTime(2026, 11, 23), issued: 999, pays: [999]), // fora
    _r('c', DateTime(2026, 11, 10), issued: 40, pays: [40]), // semana anterior
  ];
  final usecase = GetReceiptsReportUsecase(_Ledger(items), _Budgets());

  Future<ReceiptsReport> report(ReceiptsReportFilter f) async =>
      ((await usecase(f)) as Ok<ReceiptsReport>).value;

  test(
    'semana: último dia inteiro, emitido vs recebido, buckets por dia',
    () async {
      final r = await report(
        ReceiptsReportFilter(
          from: DateTime(2026, 11, 16),
          to: DateTime(2026, 11, 22),
        ),
      );
      expect(r.count, 3);
      expect(r.issued, 300);
      expect(r.paid, 280);
      expect(r.groupBy, ReceiptsReportGroupBy.day);
      expect(r.buckets.length, 7);
      expect(r.buckets.first.paid, 80);
      expect(r.buckets.last.paid, 200);
      expect(r.topBudgets.map((t) => t.budgetId), ['a', 'b']);
      expect(r.topBudgets.first.client, 'Cliente a');
    },
  );

  test('compara com período anterior de mesmo tamanho', () async {
    final r = await report(
      ReceiptsReportFilter(
        from: DateTime(2026, 11, 16),
        to: DateTime(2026, 11, 22),
        comparePrevious: true,
      ),
    );
    expect(r.previous!.count, 1);
    expect(r.previous!.paid, 40);
    expect(r.paidChangePercent, 600);
  });

  test('mês em auto agrupa por semanas segunda–domingo', () async {
    final r = await report(
      ReceiptsReportFilter(
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 30),
      ),
    );
    expect(r.groupBy, ReceiptsReportGroupBy.week);
    // 01/11 é domingo → 1º bucket só 01/11; depois semanas cheias.
    expect(r.buckets.first.end, DateTime(2026, 11, 1));
    expect(r.buckets[1].start, DateTime(2026, 11, 2));
    expect(r.buckets[1].end, DateTime(2026, 11, 8));
    expect(r.buckets.last.end, DateTime(2026, 11, 30));
    expect(r.buckets.fold<int>(0, (s, b) => s + b.count), r.count);
    expect(r.count, 5);
  });

  test('erros de período', () async {
    expect(
      await usecase(
        ReceiptsReportFilter(
          from: DateTime(2026, 11, 2),
          to: DateTime(2026, 11, 1),
        ),
      ),
      isA<Error<ReceiptsReport>>(),
    );
    expect(
      await usecase(
        ReceiptsReportFilter(
          from: DateTime(2025, 1, 1),
          to: DateTime(2026, 11, 1),
        ),
      ),
      isA<Error<ReceiptsReport>>(),
    );
  });
}
