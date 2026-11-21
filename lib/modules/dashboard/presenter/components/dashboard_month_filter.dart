import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Seletor de mês: ‹ Nov/2026 ›. Não avança além do mês atual.
class DashboardMonthFilter extends StatelessWidget {
  const DashboardMonthFilter({
    super.key,
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: DashboardStrings.previousMonth,
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(
            DashboardStrings.monthLabel(month),
            style: const TextStyle(
              color: creamColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          IconButton(
            tooltip: DashboardStrings.nextMonth,
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}
