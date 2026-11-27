import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/domain/repository/dashboard_repository.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/receipt/domain/entity/receipt_ledger.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_ledger_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Resumo de um mês: quantidade, valor orçado e recebido
/// por status. Orçamentos: 1 query por mês (com cache no repository).
/// Recebido: ledger de recibos (cache no repository).
/// Vendidos: itens dos orçamentos aprovados/finalizados (1 query por mês,
/// só feita quando há orçamento vendido).
class GetDashboardMonthSummaryUsecase {
  final BudgetRepository _budgets;
  final ReceiptLedgerRepository _ledger;
  final DashboardRepository _dashboard;

  const GetDashboardMonthSummaryUsecase(
    this._budgets,
    this._ledger,
    this._dashboard,
  );

  static const _soldStatuses = {
    DashboardStatus.approved,
    DashboardStatus.finished,
  };

  Future<Result<DashboardMonthSummary>> call(
    DateTime month, {
    bool forceRefresh = false,
  }) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final startId = start.millisecondsSinceEpoch.toString();
    final endId = (end.millisecondsSinceEpoch - 1).toString();
    final budgets = await _budgets.fetchBudgetsByMonthRange(startId, endId);
    if (budgets is Error<List<CustomerInfo>>) {
      return Result.error(budgets.error);
    }
    final list = (budgets as Ok<List<CustomerInfo>>).value;

    // Sem ledger o dashboard ainda mostra os orçamentos (recebido = 0).
    final ledgerResult = await _ledger.fetchLedger(forceRefresh: forceRefresh);
    final ledger =
        ledgerResult is Ok<ReceiptLedger> ? ledgerResult.value : null;

    final acc = <DashboardStatus, _Acc>{};
    for (final b in list) {
      final status = DashboardStatus.fromValue(b.status);
      if (status == null) continue;
      final a = acc.putIfAbsent(status, _Acc.new);
      final value = b.totalValue ?? 0;
      a.count++;
      a.budgeted += value;
      a.received += b.id == null ? 0 : (ledger?.paidFor(b.id!) ?? 0);
    }

    final soldIds = {
      for (final b in list)
        if (b.id != null &&
            _soldStatuses.contains(DashboardStatus.fromValue(b.status)))
          b.id!,
    };
    var products = (q: 0.0, t: 0.0);
    var services = (q: 0.0, t: 0.0);
    if (soldIds.isNotEmpty) {
      final items = await _dashboard.fetchMonthItems(
        startId,
        endId,
        soldIds.toList(),
        forceRefresh: forceRefresh,
      );
      // Sem itens o dashboard ainda mostra o resto (vendidos = 0).
      if (items is Ok<List<DashboardItemRaw>>) {
        for (final i in items.value) {
          if (!soldIds.contains(i.budgetId)) continue;
          switch (ItemCategory.fromValue(i.category)) {
            case ItemCategory.products:
              products = (q: products.q + i.quantity, t: products.t + i.total);
            case ItemCategory.services:
              services = (q: services.q + i.quantity, t: services.t + i.total);
            case null:
              break;
          }
        }
      }
    }

    // Recibos emitidos no mês (data do recibo = createdAt).
    var receiptsCount = 0;
    var receiptsIssued = 0.0;
    for (final r in ledger?.all ?? const <LedgerReceipt>[]) {
      if (r.createdAt.year == month.year && r.createdAt.month == month.month) {
        receiptsCount++;
        receiptsIssued += r.issued;
      }
    }

    return Result.ok(
      DashboardMonthSummary(
        receipts: DashboardReceiptsSummary(
          count: receiptsCount,
          issued: receiptsIssued,
        ),
        products: DashboardSoldTotals(quantity: products.q, total: products.t),
        services: DashboardSoldTotals(quantity: services.q, total: services.t),
        {
          for (final e in acc.entries)
            e.key: DashboardStatusSummary(
              count: e.value.count,
              budgeted: e.value.budgeted,
              received: e.value.received,
            ),
        },
      ),
    );
  }
}

class _Acc {
  int count = 0;
  double budgeted = 0;
  double received = 0;
}
