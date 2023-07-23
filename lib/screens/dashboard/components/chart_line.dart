import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../Objetos/DADOS.dart';
import '../../../constants.dart';

class ChartLine extends StatefulWidget {
  final List<DADOS> items;
  const ChartLine({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  _ChartLine createState() => _ChartLine();
}

class _ChartLine extends State<ChartLine> {
  late final bool isShowingMainData;

  Map<int, List<DADOS>> groupDataByWeek(List<DADOS> dataList) {
    Map<int, List<DADOS>> groupedData = {};
    for (var data in dataList) {
      int weekNumber = getWeekNumber(DateTime.parse(data.ID!)); // Assuming you have a date field in your DADOS class.
      groupedData.putIfAbsent(weekNumber, () => []).add(data);
    }
    return groupedData;
  }

  int getWeekNumber(DateTime date) {
    return date.day ~/ 7;
  }


  LineChartData get sampleData1 => LineChartData(
    lineTouchData: lineTouchData1,
    gridData: gridData,
    titlesData: titlesData1,
    borderData: borderData,
    lineBarsData: lineBarsData1,
    minX: 0,
    maxX: 5,
    maxY: 12,
    minY: 0,
  );

  LineTouchData get lineTouchData1 => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
    ),
  );

  FlTitlesData get titlesData1 => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: bottomTitles,
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: leftTitles(),
    ),
  );

  List<LineChartBarData> get lineBarsData1 => [
    lineChartBarData_1,
    lineChartBarData_2,
    lineChartBarData_3,
  ];

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.normal,
      fontSize: 10,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'R\$ 0';
        break;
      case 2:
        text = 'R\$ 2k';
        break;
      case 4:
        text = 'R\$ 4k';
        break;
      case 6:
        text = 'R\$ 6k';
        break;
      case 8:
        text = 'R\$ 8k';
        break;
      case 10:
        text = 'R\$ 10k';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  SideTitles leftTitles() => SideTitles(
    getTitlesWidget: leftTitleWidgets,
    showTitles: true,
    interval: 1,
    reservedSize: 30,
  );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('JUL', style: style);
        break;
      case 1:
        text = const Text('AGO', style: style);
        break;
      case 2:
        text = const Text('SET', style: style);
        break;
      case 3:
        text = const Text('OUT', style: style);
        break;
      case 4:
        text = const Text('NOV', style: style);
        break;
      case 5:
        text = const Text('DEZ', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  SideTitles get bottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 25,
    interval: 1,
    getTitlesWidget: bottomTitleWidgets,
  );

  FlGridData get gridData => const FlGridData(show: false);

  FlBorderData get borderData => FlBorderData(
    show: true,
    border: const Border(
      bottom:
      BorderSide(color: Colors.grey, width: 2),
      left: BorderSide(color: Colors.transparent),
      right: BorderSide(color: Colors.transparent),
      top: BorderSide(color: Colors.transparent),
    ),
  );

  LineChartBarData get lineChartBarData_1 => LineChartBarData(
    isCurved: true,
    color: creamColor,
    barWidth: 2,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: const [
      FlSpot(0, 8),
      FlSpot(1, 2),
      FlSpot(2, 8.8),
      FlSpot(3, 4.8),
      FlSpot(4, 5.8),
      FlSpot(5, 8.8),
    ],
  );

  LineChartBarData get lineChartBarData_2 => LineChartBarData(
    isCurved: true,
    color: buttonColor,
    barWidth: 2,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: false,
      color: buttonColor,
    ),
    spots: const [
      FlSpot(0, 0),
      FlSpot(1, 0.5),
      FlSpot(2, 0.8),
      FlSpot(3, 10),
      FlSpot(4, 6.2),
      FlSpot(5, 3),
    ],
  );

  LineChartBarData get lineChartBarData_3 => LineChartBarData(
    isCurved: true,
    color: greenColor,
    barWidth: 2,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: const [
      FlSpot(0, 10),
      FlSpot(1, 2),
      FlSpot(2, 7),
      FlSpot(3, 5.8),
      FlSpot(4, 4.2),
      FlSpot(5, 1.8),
    ],
  );


  @override
  void initState() {
    super.initState();
    isShowingMainData = true;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.23,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(
                height: 5,
              ),
              const Text(
                'Progresso mensal',
                style: TextStyle(
                  color: creamColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6, left: 0),
                  child: LineChart(
                      sampleData1
                  ),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
