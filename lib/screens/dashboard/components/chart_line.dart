import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../Objetos/MyBudgetDashboard.dart';
import '../../../constants.dart';

class ChartLine extends StatefulWidget {
  final MyBudgetDashboard item;
  const ChartLine({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  _ChartLine createState() => _ChartLine();
}

class _ChartLine extends State<ChartLine> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                createLineChartBarData(
                  spots: [
                    FlSpot(0, widget.item.qtdDoubleApproved!),
                    FlSpot(1, widget.item.qtdDoubleDisapproved!),
                    FlSpot(2, widget.item.qtdDoublePending!),
                    FlSpot(3, widget.item.qtdDoubleFinish!),
                  ],
                  color: Colors.blue,
                ),
                // Add more LineChartBarData here with different colors for each line
                createLineChartBarData(
                  spots: [
                    // Add data for the second line
                  ],
                  color: Colors.red,
                ),
                createLineChartBarData(
                  spots: [
                    // Add data for the third line
                  ],
                  color: Colors.green,
                ),
                // Add more LineChartBarData for additional lines
              ],
              minX: 0,
              maxX: 3,
              maxY: widget.item.qtdTotal!.toDouble(),
              minY: 0,
            ),
          ),
          const Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: defaultPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData createLineChartBarData({
    required List<FlSpot> spots,
    required Color color,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: bgColor,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}
