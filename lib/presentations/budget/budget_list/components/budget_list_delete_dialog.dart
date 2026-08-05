import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';

class BudgetListDeleteDialog extends StatelessWidget {
  const BudgetListDeleteDialog({
    super.key,
    required this.deleteItens,
    required this.onRemove,
    required this.onConfirm,
  });

  final List<CustomerInfo> deleteItens;
  final void Function(CustomerInfo item) onRemove;
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
                    FadeAnimationWidget(
                      delay: 1,
                      child: Container(
                        margin: EdgeInsets.only(right: we * 0.15),
                        child: Text(
                          "Remover orçamentos",
                          style: GoogleFonts.heebo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
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
                      return SizedBox(
                        height: 90,
                        child: Card(
                          color: Colors.cyan[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text("Cliente: ${deleteItens[index].customerName}",
                                style: const TextStyle(
                                  color: bgColor,
                                  letterSpacing: 0.5,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                )),
                            subtitle: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Nº orçamento: ${deleteItens[index].id}",
                                      style: const TextStyle(
                                          color: bgColor,
                                          letterSpacing: 0.5,
                                          fontSize: 12.0)),
                                  Text("Status: ${deleteItens[index].status}",
                                      style: const TextStyle(
                                          color: bgColor,
                                          letterSpacing: 0.5,
                                          fontSize: 12.0)),
                                  Text("Criado em: ${deleteItens[index].data}",
                                      style: const TextStyle(
                                          color: bgColor,
                                          letterSpacing: 0.5,
                                          fontSize: 12.0)),
                                ]),
                            trailing: Transform.scale(
                              scale: 1.7,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () {
                                  onRemove(deleteItens[index]);
                                  setState(() {});
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: bgColor,
                                  size: 23.0,
                                ),
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
                      await onConfirm();
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 70),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0))),
                    child: Text(
                      "EXCLUIR TODOS",
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
