import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/month_receipt_comparison.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_section.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Barras lado a lado por mês: verde = recebido, amarelo = falta receber.
class DashboardReceiptsComparison extends StatelessWidget {
  const DashboardReceiptsComparison({super.key, required this.items});

  final List<MonthReceiptComparison> items;

  static const _receivedColor = statusApprovedColor;
  static const _toReceiveColor = statusPendingColor;

  @override
  Widget build(BuildContext context) {
    final money = getIt<ConvertCoinRepository>();
    final maxY = items.fold<double>(
      0,
      (m, e) => [m, e.received, e.toReceive].reduce((a, b) => a > b ? a : b),
    );
    final top = maxY == 0 ? 1000.0 : maxY * 1.2;
    const axis = TextStyle(color: Colors.grey, fontSize: 11);

    return DashboardSection(
      title: DashboardStrings.receiptsComparison,
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: top,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(color: Colors.grey, width: 2),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor:
                      (_) => Colors.blueGrey.withValues(alpha: 0.9),
                  getTooltipItem:
                      (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                        money.convertFromDouble(rod.toY),
                        const TextStyle(color: whiteColor, fontSize: 12),
                      ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: top / 4,
                    getTitlesWidget:
                        (v, meta) => Text(
                          DashboardStrings.compactCurrency(v),
                          style: axis,
                        ),
                  ),
                ),
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
                          style: axis,
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
                      _rod(items[i].received, _receivedColor),
                      _rod(items[i].toReceive, _toReceiveColor),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: defaultPadding),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(_receivedColor, DashboardStrings.received),
            const SizedBox(width: defaultPadding),
            _legend(_toReceiveColor, DashboardStrings.toReceive),
          ],
        ),
      ],
    );
  }

  BarChartRodData _rod(double y, Color color) => BarChartRodData(
    toY: y,
    color: color,
    width: 14,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
  );

  Widget _legend(Color color, String label) => Row(
    children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: mutedTextColor, fontSize: 12)),
    ],
  );
}
