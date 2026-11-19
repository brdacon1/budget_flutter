/// Agrupamento do relatório de recibos.
enum ReceiptsReportGroupBy {
  day('day'),
  week('week'),
  auto('auto');

  const ReceiptsReportGroupBy(this.value);

  /// Valor fixo trafegado na tool (nunca traduzir).
  final String value;

  static ReceiptsReportGroupBy? fromValue(String? v) =>
      v == null ? auto : values.where((e) => e.value == v).firstOrNull;
}

class ReceiptsReportFilter {
  final DateTime from;
  final DateTime to;
  final ReceiptsReportGroupBy groupBy;
  final bool comparePrevious;

  const ReceiptsReportFilter({
    required this.from,
    required this.to,
    this.groupBy = ReceiptsReportGroupBy.auto,
    this.comparePrevious = false,
  });
}

/// Totais de um período: quantidade, valor emitido e valor recebido.
class ReceiptsTotals {
  final int count;
  final double issued;
  final double paid;

  const ReceiptsTotals({this.count = 0, this.issued = 0, this.paid = 0});
}

/// Fatia do período (um dia ou uma semana que começa em [start]).
class ReceiptsBucket extends ReceiptsTotals {
  final DateTime start;
  final DateTime end;

  const ReceiptsBucket({
    required this.start,
    required this.end,
    super.count,
    super.issued,
    super.paid,
  });
}

class ReceiptsTopBudget extends ReceiptsTotals {
  final String budgetId;
  final String client;

  const ReceiptsTopBudget({
    required this.budgetId,
    required this.client,
    super.count,
    super.issued,
    super.paid,
  });
}

class ReceiptsReport extends ReceiptsTotals {
  final DateTime from;
  final DateTime to;
  final ReceiptsReportGroupBy groupBy;
  final List<ReceiptsBucket> buckets;
  final List<ReceiptsTopBudget> topBudgets;
  final ReceiptsTotals? previous;

  /// Variação % do recebido vs. período anterior (null sem base).
  final double? paidChangePercent;

  const ReceiptsReport({
    required this.from,
    required this.to,
    required this.groupBy,
    required this.buckets,
    required this.topBudgets,
    this.previous,
    this.paidChangePercent,
    super.count,
    super.issued,
    super.paid,
  });
}
