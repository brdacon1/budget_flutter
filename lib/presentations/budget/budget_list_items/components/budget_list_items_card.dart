import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';

class BudgetListItemsCard extends StatelessWidget {
  const BudgetListItemsCard({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.onDelete,
  });

  final ItemsBudget item;
  final ConvertCoin moneyConvert;
  final VoidCallback onDelete;

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
            const Divider(
              thickness: 1.0,
              height: 1.0,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text(
                  "Categoria: ${item.CATEGORIA}",
                  style: const TextStyle(
                    color: whiteColor,
                    letterSpacing: 0.5,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text(
                  "Total: ${moneyConvert.convertFromDouble(item.TOTAL!)}",
                  style: const TextStyle(
                    color: whiteColor,
                    letterSpacing: 0.5,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text(
                  "Quantidade: ${item.QTD}",
                  style: const TextStyle(
                    color: whiteColor,
                    letterSpacing: 0.5,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text(
                  "Unidade de medida: ${item.MEDIDA}",
                  style: const TextStyle(
                    color: whiteColor,
                    letterSpacing: 0.5,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return Visibility(
                        visible: !item.checkBox!,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: SizedBox(
                          width: 85.0,
                          height: 52.0,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: whiteColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            onPressed: onDelete,
                            child: const Column(
                              children: <Widget>[
                                SizedBox(height: 4),
                                Icon(Icons.delete_outline_rounded, color: bgColor),
                                SizedBox(height: 2.0),
                                Text('Excluir',
                                    style: TextStyle(fontSize: 10, color: bgColor)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
