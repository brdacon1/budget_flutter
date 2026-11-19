import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/receipt/domain/entity/receipt_ledger.dart';
import 'package:oflite/modules/receipt/domain/entity/receipts_report.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_ledger_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Relatório de recibos de um período (todos os orçamentos): quantidade,
/// valor emitido (`VALORTOTAL`) e recebido (pagamentos), por dia/semana,
/// top orçamentos e comparação com o período anterior de mesmo tamanho.
///
/// Toda soma/contagem/variação é feita aqui — o modelo só repete.
class GetReceiptsReportUsecase {
  final ReceiptLedgerRepository _ledger;
  final BudgetRepository _budgets;

  const GetReceiptsReportUsecase(this._ledger, this._budgets);

  static const maxDays = 366;
  static const topLimit = 5;

  Future<Result<ReceiptsReport>> call(ReceiptsReportFilter filter) async {
    final from = _day(filter.from);
    final to = _day(filter.to);
    if (to.isBefore(from)) {
      return Result.error(const FormatException('from_after_to'));
    }
    final days = to.difference(from).inDays + 1;
    if (days > maxDays) {
      return Result.error(const FormatException('period_too_long'));
    }

    final fetched = await _ledger.fetchLedger();
    if (fetched case Error(:final error)) return Result.error(error);
    final all = (fetched as Ok<ReceiptLedger>).value.all.toList();

    final inPeriod = _between(all, from, to)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final totals = _totals(inPeriod);

    final groupBy =
        filter.groupBy == ReceiptsReportGroupBy.auto
            ? (days <= 14
                ? ReceiptsReportGroupBy.day
                : ReceiptsReportGroupBy.week)
            : filter.groupBy;

    ReceiptsTotals? previous;
    double? change;
    if (filter.comparePrevious) {
      final prevTo = from.subtract(const Duration(days: 1));
      final prevFrom = prevTo.subtract(Duration(days: days - 1));
      previous = _totals(_between(all, prevFrom, prevTo));
      if (previous.paid > 0) {
        change = (totals.paid - previous.paid) / previous.paid * 100;
      }
    }

    return Result.ok(
      ReceiptsReport(
        from: from,
        to: to,
        groupBy: groupBy,
        count: totals.count,
        issued: totals.issued,
        paid: totals.paid,
        buckets: _buckets(inPeriod, from, to, groupBy),
        topBudgets: await _top(inPeriod),
        previous: previous,
        paidChangePercent: change,
      ),
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [from] 00:00 até [to] 23:59:59.999 (o último dia entra inteiro).
  static List<LedgerReceipt> _between(
    List<LedgerReceipt> all,
    DateTime from,
    DateTime to,
  ) {
    final end = to.add(const Duration(days: 1));
    return all
        .where((r) => !r.createdAt.isBefore(from) && r.createdAt.isBefore(end))
        .toList();
  }

  static ReceiptsTotals _totals(Iterable<LedgerReceipt> list) => ReceiptsTotals(
    count: list.length,
    issued: list.fold(0, (s, r) => s + r.issued),
    paid: list.fold(0, (s, r) => s + r.paid),
  );

  /// Dia a dia, ou semanas de segunda a domingo (cortadas no período).
  static List<ReceiptsBucket> _buckets(
    List<LedgerReceipt> list,
    DateTime from,
    DateTime to,
    ReceiptsReportGroupBy groupBy,
  ) {
    final out = <ReceiptsBucket>[];
    var start = from;
    while (!start.isAfter(to)) {
      var end =
          groupBy == ReceiptsReportGroupBy.day
              ? start
              : start.add(Duration(days: DateTime.sunday - start.weekday));
      if (end.isAfter(to)) end = to;
      final t = _totals(_between(list, start, end));
      out.add(
        ReceiptsBucket(
          start: start,
          end: end,
          count: t.count,
          issued: t.issued,
          paid: t.paid,
        ),
      );
      start = DateTime(end.year, end.month, end.day + 1);
    }
    return out;
  }

  Future<List<ReceiptsTopBudget>> _top(List<LedgerReceipt> list) async {
    final groups = <String, List<LedgerReceipt>>{};
    for (final r in list) {
      groups.putIfAbsent(r.budgetId, () => []).add(r);
    }
    final ranked =
        groups.entries.map((e) => (id: e.key, t: _totals(e.value))).toList()
          ..sort((a, b) {
            final byPaid = b.t.paid.compareTo(a.t.paid);
            return byPaid != 0 ? byPaid : b.t.issued.compareTo(a.t.issued);
          });
    final out = <ReceiptsTopBudget>[];
    for (final g in ranked.take(topLimit)) {
      final budget = await _budgets.getBudgetById(g.id);
      final client = switch (budget) {
        Ok<CustomerInfo>(:final value) => value.customerName ?? '',
        _ => '',
      };
      out.add(
        ReceiptsTopBudget(
          budgetId: g.id,
          client: client,
          count: g.t.count,
          issued: g.t.issued,
          paid: g.t.paid,
        ),
      );
    }
    return out;
  }
}
