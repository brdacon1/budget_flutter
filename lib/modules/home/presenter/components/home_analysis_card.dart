import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/dashboard/domain/entity/month_receipt_comparison.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card escuro com barras de recebido × falta receber por mês.
class HomeAnalysisCard extends StatelessWidget {
  const HomeAnalysisCard({super.key, required this.items});

  final List<MonthReceiptComparison> items;

  @override
  Widget build(BuildContext context) {
    final maxY = items.fold<double>(
      0,
      (m, e) => [m, e.received, e.toReceive].reduce((a, b) => a > b ? a : b),
    );
    final top = maxY == 0 ? 1000.0 : maxY * 1.2;
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: const BoxDecoration(
        color: homeAnalysisCardColor,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            HomeStrings.analysis,
            style: const TextStyle(
              color: whiteColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: top,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= items.length) return const SizedBox();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            DashboardStrings.shortMonth(items[i].month),
                            style: const TextStyle(
                              color: mutedTextColor,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < items.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        _rod(items[i].received, statusApprovedColor),
                        _rod(items[i].toReceive, statusPendingColor),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartRodData _rod(double y, Color color) => BarChartRodData(
    toY: y,
    color: color,
    width: 12,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
  );
}
