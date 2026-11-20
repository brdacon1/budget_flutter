import 'package:oflite/shared/design_pattern/result.dart';

/// Números brutos de um orçamento (sem regra de negócio).
typedef BudgetMetricsRaw =
    ({
      List<({String? category, double total})> items,
      int receiptsCount,
      int proofsCount,
      List<({String? method, double price})> payments,
    });

abstract class BudgetMetricsRepository {
  Future<Result<BudgetMetricsRaw>> fetch(String budgetId);
}
