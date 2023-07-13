import 'package:flutter/material.dart';

import '../../../Objetos/MyBudgetDashboard.dart';
import '../../../constants.dart';
import 'chart.dart';
import 'storage_info_card.dart';

class StarageDetails extends StatefulWidget {
  final MyBudgetDashboard item;
  const StarageDetails({
    Key? key,
    required this.item
  }) : super(key: key);

  @override
  _StarageDetails createState() => _StarageDetails();
}

class _StarageDetails extends State<StarageDetails> {

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Orçamentos gerados",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: defaultPadding),
          Chart(item: widget.item),
          StorageInfoCard(
            svgSrc: Icons.check,
            iconColor: Colors.green,
            title: "Aprovados",
            amountOfFiles: widget.item.qtdIntApproved.toString(),
            numOfFiles: widget.item.qtdIntApproved!,
          ),
          StorageInfoCard(
            svgSrc: Icons.close_sharp,
            iconColor: Colors.red,
            title: "Reprovados",
            amountOfFiles: widget.item.qtdIntDisapproved.toString(),
            numOfFiles: widget.item.qtdIntDisapproved!,
          ),
          StorageInfoCard(
            svgSrc: Icons.pending_outlined,
            iconColor: Colors.amberAccent,
            title: "Pendentes",
            amountOfFiles: widget.item.qtdIntPending.toString(),
            numOfFiles: widget.item.qtdIntPending!,
          ),
          StorageInfoCard(
            svgSrc: Icons.circle,
            iconColor: Colors.white,
            title: "Finalizados",
            amountOfFiles: widget.item.qtdIntFinish.toString(),
            numOfFiles: widget.item.qtdIntFinish!,
          ),
        ],
      ),
    );
  }
}
