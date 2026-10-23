import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';

/// Barra de totais do orçamento Web — **full-width**, fixa no rodapé da aba
/// "Meus dados" (sempre visível durante o scroll). Mesmas labels da versão
/// mobile, mas sem o padding lateral que a deixava "recuada".
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
      width: double.infinity,
      color: buttonColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _line(BudgetWebStrings.totalServices,
              moneyConvert.convertFromDouble(totalServices), false),
          _line(BudgetWebStrings.totalProducts,
              moneyConvert.convertFromDouble(totalProducts), false),
          const SizedBox(height: 2),
          _line(BudgetWebStrings.totalBudget,
              moneyConvert.convertFromDouble(totalBudget), true),
        ],
      ),
    );
  }

  Widget _line(String label, String value, bool highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: bgColor,
              fontSize: highlight ? 14 : 12,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: bgColor,
              fontSize: highlight ? 14 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
