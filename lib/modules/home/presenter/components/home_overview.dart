import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_month_filter.dart';
import 'package:oflite/modules/home/presenter/components/home_overview_card.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Título + filtro de mês + grade 2×2 com os 4 status.
class HomeOverview extends StatelessWidget {
  const HomeOverview({
    super.key,
    required this.summary,
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final DashboardMonthSummary summary;
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: 12, height: 12);
    Widget row(DashboardStatus a, DashboardStatus b) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: HomeOverviewCard(status: a, data: summary.of(a))),
        gap,
        Expanded(child: HomeOverviewCard(status: b, data: summary.of(b))),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          HomeStrings.quickOverview,
          style: const TextStyle(
            color: whiteColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DashboardMonthFilter(
          month: month,
          canGoNext: canGoNext,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        gap,
        IntrinsicHeight(
          child: row(DashboardStatus.approved, DashboardStatus.pending),
        ),
        gap,
        IntrinsicHeight(
          child: row(DashboardStatus.disapproved, DashboardStatus.finished),
        ),
      ],
    );
  }
}
