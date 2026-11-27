/// Status do orçamento exibidos no dashboard.
///
/// [value] é o valor persistido no Firestore (nunca traduzir).
enum DashboardStatus {
  approved('APROVADO'),
  disapproved('REPROVADO'),
  pending('PENDENTE'),
  finished('FINALIZADO');

  const DashboardStatus(this.value);

  final String value;

  static DashboardStatus? fromValue(String? v) =>
      values.where((e) => e.value == v).firstOrNull;
}

/// Totais de um status no mês.
///
/// `budgeted` = soma de `VALORTOTAL`; `received` = soma dos pagamentos dos
/// recibos desses orçamentos.
class DashboardStatusSummary {
  final int count;
  final double budgeted;
  final double received;

  const DashboardStatusSummary({
    this.count = 0,
    this.budgeted = 0,
    this.received = 0,
  });
}

/// Total vendido de uma categoria (soma de `QTD` e de `TOTAL` dos itens).
class DashboardSoldTotals {
  final double quantity;
  final double total;

  const DashboardSoldTotals({this.quantity = 0, this.total = 0});
}

/// Recibos emitidos no mês: quantidade e valor (`VALORTOTAL` dos recibos).
class DashboardReceiptsSummary {
  final int count;
  final double issued;

  const DashboardReceiptsSummary({this.count = 0, this.issued = 0});
}

/// Resumo mensal do dashboard, por status.
///
/// `products`/`services` = itens de orçamentos aprovados ou finalizados.
class DashboardMonthSummary {
  final Map<DashboardStatus, DashboardStatusSummary> byStatus;
  final DashboardSoldTotals products;
  final DashboardSoldTotals services;
  final DashboardReceiptsSummary receipts;

  const DashboardMonthSummary(
    this.byStatus, {
    this.products = const DashboardSoldTotals(),
    this.services = const DashboardSoldTotals(),
    this.receipts = const DashboardReceiptsSummary(),
  });

  static const empty = DashboardMonthSummary({});

  DashboardStatusSummary of(DashboardStatus s) =>
      byStatus[s] ?? const DashboardStatusSummary();

  int get total => byStatus.values.fold(0, (s, e) => s + e.count);

  /// Soma do valor orçado de todos os status.
  double get totalBudgeted =>
      byStatus.values.fold(0.0, (s, e) => s + e.budgeted);
}
