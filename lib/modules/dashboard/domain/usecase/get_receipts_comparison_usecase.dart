import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/month_receipt_comparison.dart';
import 'package:oflite/modules/receipt/domain/entity/receipt_ledger.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_ledger_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Por mês, dos [months] meses até [until] (inclusive):
/// - recebido = pagamentos de todos os recibos emitidos no mês;
/// - falta receber = total de todos os orçamentos do mês − recebido.
///
/// Custo: 1 query de orçamentos cobrindo os meses + ledger em cache.
class GetReceiptsComparisonUsecase {
  final BudgetRepository _budgets;
  final ReceiptLedgerRepository _ledger;

  const GetReceiptsComparisonUsecase(this._budgets, this._ledger);

  Future<Result<List<MonthReceiptComparison>>> call(
    DateTime until, {
    int months = 4,
  }) async {
    final keys = [
      for (var i = months - 1; i >= 0; i--)
        DateTime(until.year, until.month - i),
    ];
    final end = DateTime(until.year, until.month + 1);

    final budgets = await _budgets.fetchBudgetsByMonthRange(
      keys.first.millisecondsSinceEpoch.toString(),
      (end.millisecondsSinceEpoch - 1).toString(),
    );
    if (budgets is Error<List<CustomerInfo>>) {
      return Result.error(budgets.error);
    }
    final ledger = await _ledger.fetchLedger();
    if (ledger is Error<ReceiptLedger>) return Result.error(ledger.error);

    final budgeted = {for (final k in keys) k: 0.0};
    for (final b in (budgets as Ok<List<CustomerInfo>>).value) {
      final ms = int.tryParse((b.id ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
      if (ms == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      final k = DateTime(d.year, d.month);
      if (budgeted.containsKey(k)) {
        budgeted[k] = budgeted[k]! + (b.totalValue ?? 0);
      }
    }

    final received = {for (final k in keys) k: 0.0};
    for (final r in (ledger as Ok<ReceiptLedger>).value.all) {
      final k = DateTime(r.createdAt.year, r.createdAt.month);
      if (received.containsKey(k)) received[k] = received[k]! + r.paid;
    }

    return Result.ok([
      for (final k in keys)
        MonthReceiptComparison(
          month: k,
          received: received[k]!,
          toReceive: (budgeted[k]! - received[k]!).clamp(0, double.infinity),
        ),
    ]);
  }
}
