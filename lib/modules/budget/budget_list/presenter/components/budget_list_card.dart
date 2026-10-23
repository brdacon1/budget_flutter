import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';

class BudgetListCard extends StatelessWidget {
  const BudgetListCard({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.onDelete,
    required this.onOpen,
    required this.onDuplicate,
  });

  final CustomerInfo item;
  final ConvertCoin moneyConvert;
  final VoidCallback onDelete;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;

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
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: whiteColor,
              )),
          title: Text(
            "${item.customerName}",
            maxLines: 2,
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text("Nº orçamento: ${item.id}",
              style: const TextStyle(
                  color: whiteColor, letterSpacing: 0.5, fontSize: 12.0)),
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
                  "Telefone: ${item.phone}",
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
                child: Text("Data do orçamento: ${item.data}",
                    style: const TextStyle(
                        color: whiteColor,
                        letterSpacing: 0.5,
                        fontSize: 12.0)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text("Status: ${item.status}",
                    style: const TextStyle(
                        color: whiteColor,
                        letterSpacing: 0.5,
                        fontSize: 12.0)),
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
                    "Valor total: ${moneyConvert.convertFromDouble(item.totalValue!)}",
                    style: const TextStyle(
                        color: whiteColor,
                        letterSpacing: 0.5,
                        fontSize: 12.0)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text("Criado em: ${item.data}",
                    style: const TextStyle(
                        color: whiteColor,
                        letterSpacing: 0.5,
                        fontSize: 12.0)),
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
                                    style: TextStyle(fontSize: 8.5, color: bgColor)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return SizedBox(
                        width: 85.0,
                        height: 52.0,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: whiteColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          onPressed: onOpen,
                          child: const Column(
                            children: <Widget>[
                              SizedBox(height: 4),
                              Icon(Icons.open_in_new_rounded, color: bgColor),
                              SizedBox(height: 2.0),
                              Text('Abrir',
                                  style: TextStyle(fontSize: 8.5, color: bgColor)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return SizedBox(
                        width: 85.0,
                        height: 52.0,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: whiteColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          onPressed: onDuplicate,
                          child: const Column(
                            children: <Widget>[
                              SizedBox(height: 4),
                              Icon(Icons.copy, color: bgColor),
                              SizedBox(height: 2.0),
                              Text('Duplicar',
                                  style: TextStyle(fontSize: 8.5, color: bgColor)),
                            ],
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
