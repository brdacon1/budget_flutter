import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/loading_event.dart';

class BudgetListItemsDeleteDialog extends StatelessWidget {
  const BudgetListItemsDeleteDialog({
    super.key,
    required this.deleteItens,
    required this.moneyConvert,
    required this.onRemove,
    required this.onConfirm,
  });

  final List<ItemsBudget> deleteItens;
  final ConvertCoin moneyConvert;
  final void Function(ItemsBudget item) onRemove;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return AlertDialog(
      insetPadding: const EdgeInsets.all(19),
      backgroundColor: bgColor,
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            height: 400,
            width: we,
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          Navigator.pop(context, true);
                        });
                      },
                      child: Container(
                        alignment: Alignment.topLeft,
                        margin: EdgeInsets.only(left: we * 0.0),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30.0,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(right: we * 0.15),
                      child: Text(
                        "Remover produtos",
                        style: GoogleFonts.heebo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: he * 0.02,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: deleteItens.length,
                    padding: const EdgeInsets.only(right: 0, left: 0, bottom: 40),
                    itemBuilder: (context, index) {
                      return Card(
                        color: bgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          title: Text(
                            deleteItens[index].DESCRICAO!,
                            maxLines: 1,
                            style: const TextStyle(
                              color: whiteColor,
                              letterSpacing: 0.5,
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deleteItens[index].CATEGORIA.toString(),
                                style: const TextStyle(
                                  color: whiteColor,
                                  letterSpacing: 0.5,
                                  fontSize: 10.0,
                                ),
                              ),
                              Text(
                                moneyConvert
                                    .convertFromDouble(deleteItens[index].PRECO!),
                                style: const TextStyle(
                                  color: whiteColor,
                                  letterSpacing: 0.5,
                                  fontSize: 10.0,
                                ),
                              ),
                              Text(
                                deleteItens[index].QTD.toString(),
                                style: const TextStyle(
                                  color: whiteColor,
                                  letterSpacing: 0.5,
                                  fontSize: 10.0,
                                ),
                              ),
                            ],
                          ),
                          trailing: Transform.scale(
                            scale: 1.7,
                            alignment: Alignment.center,
                            child: GestureDetector(
                              onTap: () {
                                onRemove(deleteItens[index]);
                                setState(() {});
                              },
                              child: const Icon(
                                Icons.close,
                                color: whiteColor,
                                size: 20.0,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 20)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: TextButton(
                    onPressed: () async {
                      var displayAlert = DisplayAlert();
                      var alertDisplayLoading = LoadingEvent();
                      await alertDisplayLoading.alertLoading(context);
                      try {
                        await onConfirm();
                        alertDisplayLoading.closeLoading(context);
                        await displayAlert.notification(
                            context, "Tudo Certo!", "Orçamentos removidos com sucesso!");
                      } catch (e) {
                        alertDisplayLoading.closeLoading(context);
                        await displayAlert.notificationError(
                            context, "Erro!", "Ocorreu um erro ao remover os orçamentos.");
                      }
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF0DF5E4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 70),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                    ),
                    child: Text(
                      "EXCLUIR ITENS",
                      style: GoogleFonts.heebo(
                        color: Colors.black,
                        letterSpacing: 0.5,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
