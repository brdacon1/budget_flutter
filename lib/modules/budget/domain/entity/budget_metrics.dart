import 'package:oflite/modules/receipt/domain/entity/payment_method.dart';

/// Métricas de um orçamento. `byMethod[null]` = forma de pagamento
/// desconhecida ("Outros").
class BudgetMetrics {
  final double budgetTotal;
  final double productsTotal;
  final double servicesTotal;
  final int productsCount;
  final int servicesCount;
  final int itemsCount;
  final Map<PaymentMethod?, double> byMethod;
  final int receiptsCount;
  final int proofsCount;
  final double proofsTotal;

  const BudgetMetrics({
    required this.budgetTotal,
    required this.productsTotal,
    required this.servicesTotal,
    required this.productsCount,
    required this.servicesCount,
    required this.itemsCount,
    required this.byMethod,
    required this.receiptsCount,
    required this.proofsCount,
    required this.proofsTotal,
  });

  /// Total de recibos = soma dos pagamentos registrados.
  double get receiptsTotal => byMethod.values.fold(0, (s, v) => s + v);

  double get toReceive {
    final rest = budgetTotal - receiptsTotal;
    return rest < 0 ? 0 : rest;
  }

  /// 0..1 do orçamento já recebido.
  double get receivedRatio {
    if (budgetTotal <= 0) return receiptsTotal > 0 ? 1 : 0;
    final r = receiptsTotal / budgetTotal;
    return r > 1 ? 1 : r;
  }

  /// Valor recebido que ainda não tem comprovante anexado.
  double get unprovenTotal {
    final rest = receiptsTotal - proofsTotal;
    return rest < 0 ? 0 : rest;
  }

  /// 0..1 do valor recebido coberto por comprovantes.
  double get provenRatio {
    if (receiptsTotal <= 0) return proofsTotal > 0 ? 1 : 0;
    final r = proofsTotal / receiptsTotal;
    return r > 1 ? 1 : r;
  }
}
