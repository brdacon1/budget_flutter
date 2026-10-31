import 'package:flutter/material.dart';
import 'package:oflite/modules/dashboard/domain/entity/my_budget_dashboard.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            DashboardStrings.monthBudgets,
            style: TextStyle(
              color: creamColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: defaultPadding),
          Chart(item: widget.item),
          StorageInfoCard(
            svgSrc: Icons.check,
            iconColor: Colors.green,
            title: DashboardStrings.approved,
            amountOfFiles: widget.item.qtdIntApproved.toString(),
            numOfFiles: widget.item.qtdIntApproved!,
          ),
          StorageInfoCard(
            svgSrc: Icons.close_sharp,
            iconColor: Colors.red,
            title: DashboardStrings.disapproved,
            amountOfFiles: widget.item.qtdIntDisapproved.toString(),
            numOfFiles: widget.item.qtdIntDisapproved!,
          ),
          StorageInfoCard(
            svgSrc: Icons.pending_outlined,
            iconColor: Colors.amberAccent,
            title: DashboardStrings.pending,
            amountOfFiles: widget.item.qtdIntPending.toString(),
            numOfFiles: widget.item.qtdIntPending!,
          ),
          StorageInfoCard(
            svgSrc: Icons.circle,
            iconColor: Colors.white,
            title: DashboardStrings.finished,
            amountOfFiles: widget.item.qtdIntFinish.toString(),
            numOfFiles: widget.item.qtdIntFinish!,
          ),
        ],
      ),
    );
  }
}
