import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/services/convert_coin.dart';

/// Card de item do orçamento Web — **somente visualização**.
///
/// Reutiliza o visual do card mobile (`ExpansionTileCard`) e as mesmas
/// labels, mas **sem** os botões de editar/excluir. O cliente Web não
/// adiciona nem remove itens.
class BudgetWebItemsCard extends StatelessWidget {
  const BudgetWebItemsCard({
    super.key,
    required this.item,
    required this.moneyConvert,
  });

  final ItemsBudget item;
  final ConvertCoin moneyConvert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.production_quantity_limits, color: whiteColor),
          ),
          title: Text(
            item.DESCRICAO ?? '',
            maxLines: 2,
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${BudgetWebStrings.labelPrice}: ${moneyConvert.convertFromDouble(item.PRECO ?? 0)}',
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
            ),
          ),
          children: <Widget>[
            const Divider(thickness: 1.0, height: 1.0),
            _row(BudgetWebStrings.labelCategory, item.CATEGORIA ?? '-'),
            _row(
                BudgetWebStrings.labelTotal,
                moneyConvert.convertFromDouble(item.TOTAL ?? 0)),
            _row(BudgetWebStrings.labelQuantity, '${item.QTD ?? 0}'),
            _row(BudgetWebStrings.labelMeasure, item.MEDIDA ?? '-'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
        child: Text(
          '$label: $value',
          style: const TextStyle(
            color: whiteColor,
            letterSpacing: 0.5,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
