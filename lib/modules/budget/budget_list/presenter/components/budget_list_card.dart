import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';

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
                        child: SizedBox(
                          height: 46.0,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.08),
                              foregroundColor: whiteColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: onDelete,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 16, color: whiteColor),
                                SizedBox(height: 2),
                                Text('Excluir', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: whiteColor)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Botão Duplicar (Neutro elegante)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: SizedBox(
                        height: 46.0,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            foregroundColor: whiteColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: onDuplicate,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy_rounded, size: 16, color: whiteColor),
                              SizedBox(height: 2),
                              Text('Duplicar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: whiteColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: SizedBox(
                        height: 46.0,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            foregroundColor: whiteColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: onOpen,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_new_rounded, size: 16, color: whiteColor),
                              SizedBox(height: 2),
                              Text('Abrir', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: whiteColor)),
                            ],
                          ),
                        ),
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