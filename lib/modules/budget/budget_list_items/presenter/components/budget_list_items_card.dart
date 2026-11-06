import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/button/action_button.dart';
import 'package:oflite/shared/common/widgets/label/expansion_card_label.dart';

class BudgetListItemsCard extends StatelessWidget {
  const BudgetListItemsCard({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.onDelete,
  });

  final ItemsBudget item;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onDelete;

  Widget _buildLabels() {
    return Column(
      children: [
        ExpansionCardLabel(
          nameText: "Categoria:",
          textData: "${item.CATEGORIA}",
          horizontalPadding: 12,
          verticalPadding: 5,
        ),
        ExpansionCardLabel(
          nameText: "Total:",
          textData: moneyConvert.convertFromDouble(item.TOTAL!),
          horizontalPadding: 12,
          verticalPadding: 5,
        ),
        ExpansionCardLabel(
          nameText: "Quantidade:",
          textData: '${item.QTD}',
          horizontalPadding: 12,
          verticalPadding: 5,
        ),
        ExpansionCardLabel(
          nameText: "Unidade de medida:",
          textData: '${item.MEDIDA}',
          horizontalPadding: 12,
          verticalPadding: 5,
        ),
      ],
    );
  }

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
            item.DESCRICAO!,
            maxLines: 2,
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Preço: ${moneyConvert.convertFromDouble(item.PRECO!)}",
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
            ),
          ),
          children: <Widget>[
            const Divider(thickness: 1.0, height: 1.0),
            _buildLabels(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionButton(
                        icon:
                            item.checkBox!
                                ? Icons.check_circle_outline
                                : Icons.delete_outline_rounded,
                        label:
                            item.checkBox!
                                ? 'Selecionado para remover'
                                : 'Excluir',
                        onPressed: onDelete,
                        backgroundColor:
                            item.checkBox!
                                ? buttonColor.withValues(alpha: 0.20)
                                : whiteColor.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
