import 'package:oflite/shared/design_pattern/result.dart';

typedef DashboardItemRaw =
    ({String? budgetId, String? category, double quantity, double total});

abstract class DashboardRepository {
  /// Itens de todos os orçamentos com id em [startId]..[endId].
  /// [budgetIds] só é usado no fallback (leitura por orçamento).
  Future<Result<List<DashboardItemRaw>>> fetchMonthItems(
    String startId,
    String endId,
    List<String> budgetIds, {
    bool forceRefresh = false,
  });
}
