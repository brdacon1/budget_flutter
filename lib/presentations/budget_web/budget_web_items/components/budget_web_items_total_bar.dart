import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/strings/budget_web_strings.dart';
import 'package:oflite/services/convert_coin.dart';

/// Barra de totais do orçamento Web — mesmo visual/labels da versão mobile.
class BudgetWebItemsTotalBar extends StatelessWidget {
  const BudgetWebItemsTotalBar({
    super.key,
    required this.moneyConvert,
    required this.totalProducts,
    required this.totalServices,
    required this.totalBudget,
  });

  final ConvertCoin moneyConvert;
  final double totalProducts;
  final double totalServices;
  final double totalBudget;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65.0,
      color: buttonColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _line(BudgetWebStrings.totalServices, moneyConvert.convertFromDouble(totalServices)),
          _line(BudgetWebStrings.totalProducts, moneyConvert.convertFromDouble(totalProducts)),
          _line(BudgetWebStrings.totalBudget, moneyConvert.convertFromDouble(totalBudget)),
        ],
      ),
    );
  }

  Padding _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          '$label: $value',
          style: const TextStyle(
            color: bgColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
