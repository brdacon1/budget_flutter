import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/my_budget_dashboard.dart';
import '../../../common/constants/constants.dart';

class Chart extends StatefulWidget {
  final MyBudgetDashboard item;
  const Chart({
    Key? key,
    required this.item
  }) : super(key: key);
  @override
  _Chart createState() => _Chart();
}

class _Chart extends State<Chart> {
  List<PieChartSectionData> paiChartSelectionDatas = [];

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    paiChartSelectionDatas = [
      PieChartSectionData(
        color: Colors.green,
        value: widget.item.qtdDoubleApproved,
        showTitle: false,
        radius: widget.item.qtdDoubleApproved! * 2,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: widget.item.qtdDoubleDisapproved,
        showTitle: false,
        radius: widget.item.qtdDoubleDisapproved! * 2,
      ),
      PieChartSectionData(
        color: Colors.amberAccent,
        value: widget.item.qtdDoublePending,
        showTitle: false,
        radius: widget.item.qtdDoublePending! * 2,
      ),
      PieChartSectionData(
        color: Colors.white,
        value: widget.item.qtdDoubleFinish,
        showTitle: false,
        radius: widget.item.qtdDoubleFinish! * 2,
      ),
    ];
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: paiChartSelectionDatas,
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: defaultPadding),
                Text(
                  widget.item.qtdTotal.toString(),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 34
                  ),
                ),
                Text("Total",
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}


