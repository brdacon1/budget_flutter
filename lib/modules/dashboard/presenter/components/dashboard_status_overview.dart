import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_section.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_status_card.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_status_style.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Rosca com o total do mês + um card por status.
class DashboardStatusOverview extends StatelessWidget {
  const DashboardStatusOverview({super.key, required this.summary});

  final DashboardMonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodyLarge!;
    return DashboardSection(
      title: DashboardStrings.monthBudgets,
      children: [
        SizedBox(
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 46,
                  startDegreeOffset: -90,
                  sections: [
                    if (summary.total == 0)
                      PieChartSectionData(
                        color: cardBorderColor,
                        value: 1,
                        showTitle: false,
                        radius: 12,
                      ),
                    for (final s in DashboardStatus.values)
                      if (summary.of(s).count > 0)
                        PieChartSectionData(
                          color: s.color,
                          value: summary.of(s).count.toDouble(),
                          showTitle: false,
                          radius: 12,
                        ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${summary.total}',
                    style: text.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  Text(
                    DashboardStrings.total,
                    style: text.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding / 2),
        // Grade 2×2: metade da altura da lista anterior.
        for (final pair in const [
          [DashboardStatus.approved, DashboardStatus.disapproved],
          [DashboardStatus.pending, DashboardStatus.finished],
        ])
          Padding(
            padding: const EdgeInsets.only(top: defaultPadding / 2),
            child: Row(
              children: [
                Expanded(
                  child: DashboardStatusCard(
                    status: pair[0],
                    item: summary.of(pair[0]),
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                Expanded(
                  child: DashboardStatusCard(
                    status: pair[1],
                    item: summary.of(pair[1]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
