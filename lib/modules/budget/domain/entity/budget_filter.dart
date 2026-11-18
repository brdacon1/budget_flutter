import 'package:oflite/modules/budget/domain/entity/budget_status.dart';

/// Filtro de consulta de orçamentos. Período inclusivo em dias inteiros.
class BudgetFilter {
  final BudgetStatus? status;
  final DateTime? from;
  final DateTime? to;
  final String? clientName;

  const BudgetFilter({this.status, this.from, this.to, this.clientName});
}
