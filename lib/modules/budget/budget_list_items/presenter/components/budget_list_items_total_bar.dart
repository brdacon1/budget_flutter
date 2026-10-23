import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';

class BudgetListItemsTotalBar extends StatelessWidget {
  const BudgetListItemsTotalBar({super.key, required this.viewModel});

  final dynamic viewModel;

  @override
  Widget build(BuildContext context) {
    final ConvertCoin moneyConvert = viewModel.moneyConvert;
    return Container(
      height: 65.0,
      color: buttonColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              "Total Serviços: ${moneyConvert.convertFromDouble(viewModel.totalServices)}",
              style: const TextStyle(
                color: bgColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              "Total produtos: ${moneyConvert.convertFromDouble(viewModel.totalProducts)}",
              style: const TextStyle(
                color: bgColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              "Total orçamento: ${moneyConvert.convertFromDouble(viewModel.totalBudget)}",
              style: const TextStyle(
                color: bgColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
