import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_metrics.dart';
import 'package:oflite/modules/budget/domain/repository/budget_metrics_repository.dart';
import 'package:oflite/modules/receipt/domain/entity/payment_method.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Monta as métricas de um orçamento: total vem do [CustomerInfo] (sem
/// leitura) e os pagamentos são agrupados por [PaymentMethod].
class GetBudgetMetricsUsecase {
  final BudgetMetricsRepository _repository;

  const GetBudgetMetricsUsecase(this._repository);

  Future<Result<BudgetMetrics>> call(CustomerInfo budget) async {
    final res = await _repository.fetch(budget.id ?? '');
    switch (res) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        final byMethod = <PaymentMethod?, double>{};
        for (final p in value.payments) {
          final m = PaymentMethod.fromValue(p.method);
          byMethod[m] = (byMethod[m] ?? 0) + p.price;
        }
        var products = 0.0;
        var services = 0.0;
        var productsCount = 0;
        var servicesCount = 0;
        for (final i in value.items) {
          switch (ItemCategory.fromValue(i.category)) {
            case ItemCategory.products:
              products += i.total;
              productsCount++;
            case ItemCategory.services:
              services += i.total;
              servicesCount++;
            case null:
              break;
          }
        }
        return Result.ok(
          BudgetMetrics(
            budgetTotal: budget.totalValue ?? 0,
            productsTotal: products,
            servicesTotal: services,
            productsCount: productsCount,
            servicesCount: servicesCount,
            itemsCount: value.items.length,
            byMethod: byMethod,
            receiptsCount: value.receiptsCount,
            proofsCount: value.proofsCount,
            proofsTotal: value.proofsTotal,
          ),
        );
    }
  }
}
