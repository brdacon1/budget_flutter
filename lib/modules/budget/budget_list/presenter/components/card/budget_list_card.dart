import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/common/widgets/button/action_button.dart';

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
  final ConvertCoinRepository moneyConvert;
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
              padding: const EdgeInsets.only(bottom: 12, top: 12, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (!item.checkBox!)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ActionButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Excluir',
                          onPressed: onDelete,
                        ),
                      ),
                    ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionButton(
                        icon: Icons.copy_rounded,
                        label: 'Duplicar',
                        onPressed: onDuplicate,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionButton(
                        icon: Icons.open_in_new_rounded,
                        label: 'Abrir',
                        onPressed: onOpen,
                      ),
                    ),
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