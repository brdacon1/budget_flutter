import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';

class BudgetListDuplicateDialog extends StatelessWidget {
  const BudgetListDuplicateDialog({super.key, required this.onConfirm});

  final Future<void> Function(bool clientData, bool quoteItems, bool comments)
      onConfirm;

  @override
  Widget build(BuildContext context) {
    bool duplicateClientData = false;
    bool duplicateQuoteItems = false;
    bool duplicateComments = false;
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return AlertDialog(
      insetPadding: const EdgeInsets.all(15),
      backgroundColor: bgColor,
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            height: 360,
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
                      margin: EdgeInsets.only(right: we * 0.22),
                      child: Text(
                        "Duplicar orçamento",
                        style: GoogleFonts.heebo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: he * 0.02,
                ),
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: Card(
                      color: Colors.cyan[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CheckboxListTile(
                            side: const BorderSide(
                              color: bgColor,
                            ),
                            checkColor: Colors.white,
                            activeColor: bgColor,
                            title: Text(
                              "Duplicar dados do cliente",
                              style: GoogleFonts.heebo(
                                color: Colors.black,
                                letterSpacing: 0.5,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: duplicateClientData,
                            onChanged: (bool? value) {
                              setState(() {
                                duplicateClientData = value!;
                              });
                            },
                          ),
                          SizedBox(
                            height: he * 0.02,
                          ),
                          CheckboxListTile(
                            side: const BorderSide(
                              color: bgColor,
                            ),
                            checkColor: Colors.white,
                            activeColor: bgColor,
                            title: Text(
                              "Duplicar itens do orçamento",
                              style: GoogleFonts.heebo(
                                color: Colors.black,
                                letterSpacing: 0.5,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: duplicateQuoteItems,
                            onChanged: (bool? value) {
                              setState(() {
                                duplicateQuoteItems = value!;
                              });
                            },
                          ),
                          SizedBox(
                            height: he * 0.02,
                          ),
                          CheckboxListTile(
                            side: const BorderSide(
                              color: bgColor,
                            ),
                            checkColor: Colors.white,
                            activeColor: bgColor,
                            title: Text(
                              "Duplicar comentários",
                              style: GoogleFonts.heebo(
                                color: Colors.black,
                                letterSpacing: 0.5,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: duplicateComments,
                            onChanged: (bool? value) {
                              setState(() {
                                duplicateComments = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: TextButton(
                      onPressed: () async {
                        if (!duplicateClientData &
                            !duplicateQuoteItems &
                            !duplicateComments) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Por favor selecione alguma opção")),
                          );
                        } else {
                          await onConfirm(duplicateClientData, duplicateQuoteItems,
                              duplicateComments);
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 70,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        "DUPLICAR",
                        style: GoogleFonts.heebo(
                          color: Colors.black,
                          letterSpacing: 0.5,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
