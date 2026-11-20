import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_metrics.dart';
import 'package:oflite/modules/budget/domain/usecase/get_budget_metrics_usecase.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Métricas de um orçamento. Carrega uma vez; recarrega só no pull-to-refresh.
class BudgetMetricsViewModel extends ChangeNotifier {
  final CustomerInfo item;
  final GetBudgetMetricsUsecase _getMetrics;
  final ConvertCoinRepository moneyConvert;

  BudgetMetricsViewModel({
    required this.item,
    GetBudgetMetricsUsecase? getMetrics,
    ConvertCoinRepository? convertCoin,
  }) : _getMetrics = getMetrics ?? getIt<GetBudgetMetricsUsecase>(),
       moneyConvert = convertCoin ?? getIt<ConvertCoinRepository>();

  BudgetMetrics? metrics;
  bool loading = true;
  bool loadError = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final res = await _getMetrics(item);
    switch (res) {
      case Ok(:final value):
        metrics = value;
        loadError = false;
      case Error():
        loadError = true;
    }
    loading = false;
    notifyListeners();
  }

  String money(double v) => moneyConvert.convertFromDouble(v);
}
