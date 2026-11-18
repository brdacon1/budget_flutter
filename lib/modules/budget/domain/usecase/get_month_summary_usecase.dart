import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_filter.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Totais de um mês agrupados por status. Fonte única dos números que a IA
/// mostra — o modelo nunca soma.
class MonthSummary {
  final DateTime month;
  final int count;
  final double total;

  /// status persistido → (quantidade, valor).
  final Map<String, ({int count, double total})> byStatus;

  const MonthSummary({
    required this.month,
    required this.count,
    required this.total,
    required this.byStatus,
  });
}

class GetMonthSummaryUsecase {
  final ListBudgetsUsecase _listBudgets;

  const GetMonthSummaryUsecase(this._listBudgets);

  Future<Result<MonthSummary>> call(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final result = await _listBudgets(BudgetFilter(from: first, to: last));
    if (result case Error(:final error)) return Result.error(error);

    final budgets = (result as Ok<List<CustomerInfo>>).value;
    final byStatus = {
      for (final s in BudgetStatus.values) s.value: (count: 0, total: 0.0),
    };
    var total = 0.0;
    for (final b in budgets) {
      final value = b.totalValue ?? 0;
      total += value;
      final key = BudgetStatus.fromValue(b.status)?.value;
      if (key == null) continue;
      final cur = byStatus[key]!;
      byStatus[key] = (count: cur.count + 1, total: cur.total + value);
    }
    return Result.ok(
      MonthSummary(
        month: first,
        count: budgets.length,
        total: total,
        byStatus: byStatus,
      ),
    );
  }
}
