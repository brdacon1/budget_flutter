import 'package:flutter/material.dart';
import 'package:oflite/modules/dashboard/presenter/components/storage_info_card.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/shared/models/month_calculate.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'chart_line.dart';

class MonthEvolution extends StatefulWidget {
  final MonthCalculate item;
  const MonthEvolution({Key? key, required this.item}) : super(key: key);
  @override
  _MonthEvolution createState() => _MonthEvolution();
}

class _MonthEvolution extends State<MonthEvolution> {
  ConvertCoin moneyConvert = ConvertCoin();
  late double totalApproved = 0;
  late double totalReproved = 0;
  late double totalPending = 0;
  late double totalFinish = 0;

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    totalApproved = (widget.item.totalApprovedMonth_0!
        + widget.item.totalApprovedMonth_1!
        + widget.item.totalApprovedMonth_2!
        + widget.item.totalApprovedMonth_3!) * 1000;

    totalReproved = (widget.item.totalReprovedMonth_0!
        + widget.item.totalReprovedMonth_1!
        + widget.item.totalReprovedMonth_2!
        + widget.item.totalReprovedMonth_3!) * 1000;

    totalPending  = (widget.item.totalPendingMonth_0!
        + widget.item.totalPendingMonth_1!
        + widget.item.totalPendingMonth_2!
        + widget.item.totalPendingMonth_3!) * 1000;

    totalFinish   = (widget.item.totalFinishMonth_0!
        + widget.item.totalFinishMonth_1!
        + widget.item.totalFinishMonth_2!
        + widget.item.totalFinishMonth_3!) * 1000;

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ChartLine(item: widget.item),
          const SizedBox(height: 30),
          const Text(
            'Resultado semanal',
            style: TextStyle(
              color: creamColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: defaultPadding),
          StorageInfoCard(
            svgSrc: Icons.check,
            iconColor: Colors.green,
            title: "Aprovados",
            amountOfFiles: moneyConvert.convertFromDouble(totalApproved),
            numOfFiles: totalApproved.toInt(),
          ),
          StorageInfoCard(
            svgSrc: Icons.close_sharp,
            iconColor: Colors.red,
            title: "Reprovados",
            amountOfFiles: moneyConvert.convertFromDouble(totalReproved),
            numOfFiles: totalReproved.toInt(),
          ),
          StorageInfoCard(
            svgSrc: Icons.pending_outlined,
            iconColor: Colors.amberAccent,
            title: "Pendentes",
            amountOfFiles: moneyConvert.convertFromDouble(totalPending),
            numOfFiles: totalPending.toInt(),
          ),
          StorageInfoCard(
            svgSrc: Icons.circle,
            iconColor: Colors.white,
            title: "Finalizados",
            amountOfFiles: moneyConvert.convertFromDouble(totalFinish),
            numOfFiles: totalFinish.toInt(),
          ),
        ],
      ),
    );
  }
}

