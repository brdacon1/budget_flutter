import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/customer_info.dart';
import '../../../models/month_calculate.dart';
import '../../../common/constants/constants.dart';

class ChartLine extends StatefulWidget {
  final MonthCalculate item;
  const ChartLine({
    Key? key,
    required this.item
  }) : super(key: key);

  @override
  _ChartLine createState() => _ChartLine();
}

class _ChartLine extends State<ChartLine> {
  late final bool isShowingMainData;
  double? sizeLine = 0;
  Map<int, List<CustomerInfo>> groupDataByWeek(List<CustomerInfo> dataList) {
    Map<int, List<CustomerInfo>> groupedData = {};
    for (var data in dataList) {
      int weekNumber = getWeekNumber(DateTime.parse(data.id!)); // Assuming you have a date field in your DADOS class.
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
    maxX: 3,
    maxY: sizeLine! + 2,
    minY: 0,
  );

  double roundToTwoDecimals(double? value) {
    // Usa o método toStringAsFixed() para arredondar o valor para duas casas decimais
    return double.parse(value!.toStringAsFixed(0));
  }


  LineTouchData get lineTouchData1 => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (LineBarSpot touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
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
    lineChartBarData_4,
  ];

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.normal,
      fontSize: 12,
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
      case 12:
        text = 'R\$ 12k';
        break;
      case 14:
        text = 'R\$ 14k';
        break;
      case 16:
        text = 'R\$ 16k';
        break;
      case 18:
        text = 'R\$ 18k';
        break;
      case 20:
        text = 'R\$ 20k';
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
    reservedSize: 42,
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
        text = const Text('Sem. 1', style: style);
        break;
      case 1:
        text = const Text('Sem. 2', style: style);
        break;
      case 2:
        text = const Text('Sem. 3', style: style);
        break;
      case 3:
        text = const Text('Sem. 4', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      meta: meta,
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
      bottom: BorderSide(color: Colors.grey, width: 2),
      left: BorderSide(color: Colors.transparent),
      right: BorderSide(color: Colors.transparent),
      top: BorderSide(color: Colors.transparent),
    ),
  );

  LineChartBarData get lineChartBarData_1 => LineChartBarData(
    isCurved: true,
    color: redColor,
    barWidth: 3,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: [
      FlSpot(0, widget.item.totalReprovedMonth_0!),
      FlSpot(1, widget.item.totalReprovedMonth_1!),
      FlSpot(2, widget.item.totalReprovedMonth_2!),
      FlSpot(3, widget.item.totalReprovedMonth_3!),
    ],
  );

  LineChartBarData get lineChartBarData_2 => LineChartBarData(
    isCurved: true,
    color: greenColor,
    barWidth: 3,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: false,
      color: buttonColor,
    ),
    spots: [
      FlSpot(0,  widget.item.totalApprovedMonth_0!),
      FlSpot(1, widget.item.totalApprovedMonth_1!),
      FlSpot(2, widget.item.totalApprovedMonth_2!),
      FlSpot(3, widget.item.totalApprovedMonth_3!),
    ],
  );

  LineChartBarData get lineChartBarData_3 => LineChartBarData(
    isCurved: true,
    color: Colors.yellow,
    barWidth: 3,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: false,
      color: buttonColor,
    ),
    spots: [
      FlSpot(0, widget.item.totalPendingMonth_0!),
      FlSpot(1, widget.item.totalPendingMonth_1!),
      FlSpot(2, widget.item.totalPendingMonth_2!),
      FlSpot(3, widget.item.totalPendingMonth_3!),
    ],
  );

  LineChartBarData get lineChartBarData_4 => LineChartBarData(
    isCurved: true,
    color: Colors.white,
    barWidth: 3,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: false,
      color: buttonColor,
    ),
    spots: [
      FlSpot(0, widget.item.totalFinishMonth_0!),
      FlSpot(1, widget.item.totalFinishMonth_1!),
      FlSpot(2, widget.item.totalFinishMonth_2!),
      FlSpot(3, widget.item.totalFinishMonth_3!),
    ],
  );

  double findLargestValue(double? value1, double? value2, double? value3, double? value4) {
    double largestValue = 0.0;

    if (value1 != null && value1 > largestValue) {
      largestValue = value1;
    }

    if (value2 != null && value2 > largestValue) {
      largestValue = value2;
    }

    if (value3 != null && value3 > largestValue) {
      largestValue = value3;
    }

    if (value4 != null && value4 > largestValue) {
      largestValue = value4;
    }

    return largestValue;
  }


  @override
  void initState() {
    super.initState();
    isShowingMainData = true;
  }

  @override
  Widget build(BuildContext context) {
    double largestValueReproved = findLargestValue(
      widget.item.totalReprovedMonth_0,
      widget.item.totalReprovedMonth_1,
      widget.item.totalReprovedMonth_2,
      widget.item.totalReprovedMonth_3,
    );

    double largestValueApproved = findLargestValue(
      widget.item.totalApprovedMonth_0,
      widget.item.totalApprovedMonth_1,
      widget.item.totalApprovedMonth_2,
      widget.item.totalApprovedMonth_3,
    );

    double largestValuePending = findLargestValue(
      widget.item.totalPendingMonth_0,
      widget.item.totalPendingMonth_1,
      widget.item.totalPendingMonth_2,
      widget.item.totalPendingMonth_3,
    );

    double largestValueFinish = findLargestValue(
      widget.item.totalFinishMonth_0,
      widget.item.totalFinishMonth_1,
      widget.item.totalFinishMonth_2,
      widget.item.totalFinishMonth_3,
    );

    sizeLine = findLargestValue(
      largestValueReproved,
      largestValueApproved,
      largestValuePending,
      largestValueFinish,
    );
    setState(() {

    });
    sizeLine = roundToTwoDecimals(sizeLine);
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
                'Progresso semanal',
                style: TextStyle(
                  color: creamColor,
                  fontSize: 17,
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
                  child: LineChart(sampleData1),
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
