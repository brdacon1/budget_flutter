import 'package:flutter/foundation.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/domain/entity/month_receipt_comparison.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_dashboard_month_summary_usecase.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_receipts_comparison_usecase.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class DashboardViewModel extends ChangeNotifier {
  final GetDashboardMonthSummaryUsecase _getSummary;
  final GetReceiptsComparisonUsecase _getComparison;

  DashboardViewModel(this._getSummary, this._getComparison) {
    loadCommand = Command1(_load);
  }

  /// Arg = forceRefresh.
  late final Command1<void, bool> loadCommand;

  DateTime _month = _currentMonth();
  DateTime get month => _month;

  bool get canGoNext => _month.isBefore(_currentMonth());

  DashboardMonthSummary _summary = DashboardMonthSummary.empty;
  DashboardMonthSummary get summary => _summary;

  List<MonthReceiptComparison> _comparison = const [];
  List<MonthReceiptComparison> get comparison => _comparison;

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previousMonth() => _changeMonth(-1);

  void nextMonth() {
    if (canGoNext) _changeMonth(1);
  }

  void _changeMonth(int delta) {
    _month = DateTime(_month.year, _month.month + delta);
    notifyListeners();
    loadCommand.execute(false);
  }

  Future<Result<void>> _load(bool forceRefresh) async {
    // Em sequência: a 2ª chamada reaproveita o ledger em cache.
    final month = _month;
    final summary = await _getSummary(month, forceRefresh: forceRefresh);
    final comparison = await _getComparison(month);
    // Usuário trocou de mês no meio da carga: descarta o resultado velho.
    if (month != _month) return const Result.ok(null);
    if (summary is Ok<DashboardMonthSummary>) _summary = summary.value;
    if (comparison is Ok<List<MonthReceiptComparison>>) {
      _comparison = comparison.value;
    }
    notifyListeners();
    return summary is Error<DashboardMonthSummary>
        ? Result.error(summary.error)
        : const Result.ok(null);
  }
}
