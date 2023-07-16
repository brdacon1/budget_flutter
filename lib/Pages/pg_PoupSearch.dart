import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oflite/Pages/pg_TabOrcamento.dart';
import 'package:oflite/Services/display_alert.dart';
import 'package:oflite/Services/loading_event.dart';
import 'package:oflite/anmition/fadeanimation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supercharged/supercharged.dart';
import '../Models/Db.dart';
import '../Objetos/DADOS.dart';
import 'package:oflite/Objetos/globalUIDOrcamento.dart' as Orcamento;
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import 'package:badges/badges.dart' as badges;

import '../constants.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

class pg_PoupSearch extends StatefulWidget {
  @override
  State<pg_PoupSearch> createState() => _pg_PoupSearch();
}

class _pg_PoupSearch extends State<pg_PoupSearch> {
  DADOS customerBudget = DADOS();
  Color enabled = const Color(0xFF827F8A);
  var _foundUsers = <DADOS>[];
  var deleteItens = <DADOS>[];
  DADOS novo = DADOS();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool deleteVisible = false;
  bool checkBoxAppear = false;

  @override
  initState() {
    try {
      setState(() async {
        await getInformationOrcamento();
        setState(() {});
      });
    } catch (e) {}
    super.initState();

  }

  Future<void> _duplicateEvent(bool clientData, bool quoteItems, bool comments)async {
      var db = Db();
      String? ID = Orcamento.IDORCAMENTO;
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);
      if(clientData) {
        await db.getInformationOrcamento1().then((value) => {
          if(value.NOMECLIENTE!.isNotEmpty)
            {
              customerBudget.NOMECLIENTE = value.NOMECLIENTE,
              customerBudget.FONE = value.FONE,
              customerBudget.STATUS = value.STATUS,
              customerBudget.EMAIL = value.EMAIL,
              customerBudget.ENDERECO = value.ENDERECO,
              customerBudget.GERADO = value.GERADO,
              customerBudget.NOMEEMPRESA = value.NOMEEMPRESA,
              customerBudget.CEP = value.CEP,
              customerBudget.RUA = value.RUA,
              customerBudget.CITY = value.CITY,
              customerBudget.BAIRRO = value.BAIRRO,
              customerBudget.DATA = formatted,
              customerBudget.ID = DateTime.now().millisecondsSinceEpoch.toString(),
              db.saveBudget(customerBudget).then((value)  async {
                var quoteItemsObject = await db.getListItemsGenerator(ID);
                var commentsObject = await db.getListComment(ID);
                if(quoteItems) {
                  if(quoteItemsObject.isNotEmpty) {
                    db.saveItemsList(quoteItemsObject);
                  }
                }
                if(comments) {
                  if(commentsObject.isNotEmpty) {
                    db.addComment(commentsObject);
                  }
                }
              }),
            }}
        );
      }
      else {
          customerBudget.NOMECLIENTE = "Duplicado de: ${ID}";
          customerBudget.FONE = "";
          customerBudget.STATUS = "";
          customerBudget.EMAIL = "";
          customerBudget.ENDERECO = "";
          customerBudget.GERADO = "";
          customerBudget.NOMEEMPRESA = "";
          customerBudget.CEP = "";
          customerBudget.RUA = "";
          customerBudget.CITY = "";
          customerBudget.BAIRRO = "";
          customerBudget.DATA = formatted;
          customerBudget.ID = DateTime.now().millisecondsSinceEpoch.toString();

          db.saveBudget(customerBudget).then((value)  async {
             var quoteItemsObject = await db.getListItemsGenerator(ID);
             var commentsObject = await db.getListComment(ID);
             if(quoteItems) {
               if(quoteItemsObject.isNotEmpty) {
                  db.saveItemsList(quoteItemsObject);
               }
             }
             if(comments) {
               if(commentsObject.isNotEmpty) {
                  db.addComment(commentsObject);
               }
             }
          });
      }
  }

  Future<void> _dialogDuplicate() {
    bool duplicateClientData = false;
    bool duplicateQuoteItems = false;
    bool duplicateComments = false;
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
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
                                checkColor:  Colors.white,
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
                                checkColor:  Colors.white,
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
                                checkColor:  Colors.white,
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
                    Padding(padding: const EdgeInsets.only(top: 15),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: TextButton(
                                onPressed: () async {
                                     var alertDisplayLoading = LoadingEvent();
                                     var displayAlert = DisplayAlert();
                                     if(!duplicateClientData & !duplicateQuoteItems & !duplicateComments) {
                                       displayAlert.notificationError(context, "Erro!", "Por favor selecione alguma opção");
                                     }
                                     else{
                                           await alertDisplayLoading.alertLoading(context);
                                           await _duplicateEvent(duplicateClientData,duplicateQuoteItems,duplicateComments).then((value) => {
                                                 alertDisplayLoading.closeLoading(context),
                                                 Navigator.of(context, rootNavigator: true).pop(),
                                           });
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
      },
    ).then((value) async {
      await getInformationOrcamento().then((value) => {
            setState(() {}),
      });
    });
  }

  Future<void> _dialogDeleteBuilder() {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
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
                        FadeAnimation(
                          delay: 1,
                          child: Container(
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
                        ),
                      ],
                    ),
                    SizedBox(
                      height: he * 0.02,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: deleteItens.length,
                        padding: const EdgeInsets.only(
                            right: 0, left: 0, bottom: 40),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            height: 90,
                            child: Card(
                              color: Colors.cyan[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                title: Text(
                                    "Cliente: ${deleteItens[index].NOMECLIENTE}",
                                    style: const TextStyle(
                                      color: bgColor,
                                      letterSpacing: 0.5,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                    )),
                                subtitle: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Nº orçamento: ${deleteItens[index].ID}",
                                          style: const TextStyle(
                                              color: bgColor,
                                              letterSpacing: 0.5,
                                              fontSize: 12.0)),
                                      Text(
                                          "Status: ${deleteItens[index].STATUS}",
                                          style: const TextStyle(
                                              color: bgColor,
                                              letterSpacing: 0.5,
                                              fontSize: 12.0)),
                                      Text(
                                          "Criado em: ${deleteItens[index].DATA}",
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
                                      _foundUsers[deleteItens[index].indice]
                                          .checkBox = false;
                                      deleteItens.remove(deleteItens[index]);
                                      if (deleteItens.isEmpty) {
                                        deleteVisible = false;
                                        checkBoxAppear = false;
                                      }
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
                            var displayAlert = DisplayAlert();
                            var alertDisplayLoading = LoadingEvent();
                            await alertDisplayLoading.alertLoading(context);

                            try {
                              await deleteData();
                              deleteItens.clear();
                              deleteVisible = false;
                              checkBoxAppear = false;

                              alertDisplayLoading.closeLoading(context);
                              await displayAlert.notification(context, "Tudo Certo!", "Orçamentos removidos com sucesso!");
                              setState(() {});
                            } catch (e) {
                              alertDisplayLoading.closeLoading(context);
                              await displayAlert.notificationError(context, "Erro!", "Ocorreu um erro ao remover os orçamentos.");
                            }
                          },
                          style: TextButton.styleFrom(
                              backgroundColor: buttonColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 70),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0))),
                          child: Text(
                            "EXCLUIR ITENS",
                            style: GoogleFonts.heebo(
                              color: Colors.black,
                              letterSpacing: 0.5,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((value) {
      setState(() {});
    });
  }

  Future<bool> deleteData() async {
    bool result = false;
    int count = deleteItens.length - 1;
    for (int i = 0; i < deleteItens.length; i++) {
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
          .doc(deleteItens[i].ID)
          .delete()
          .then((value) async {
        if (i == count) {
          setState(() {
            deleteItens.clear();
            deleteVisible = false;
          });
          await getInformationOrcamento();
          setState(() {});
        }
      });
    }
    return result;
  }

  Future<List<DADOS>> getInformationOrcamento() async {
    int index = 0;
    _foundUsers.clear();
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
        .orderBy('ID', descending: true)
        .get()
        .then((value) async {
      for (var questionTmp in value.docs) {
        _foundUsers.add(DADOS.fromMap(questionTmp));
        _foundUsers[index].checkBox = false;
        index++;
      }
    });
    return _foundUsers;
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
        SizedBox(
          height: he * 0.04,
        ),
        SizedBox(
          height: he * 0.03,
        ),
        FadeAnimation(
          delay: 1,
          child: Container(
            margin: const EdgeInsets.only(right: 125.0),
            child: Text(
              "Meus orçamentos",
              style: GoogleFonts.heebo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  letterSpacing: 2),
            ),
          ),
        ),
        SizedBox(
          height: he * 0.03,
        ),
        FadeAnimation(
          delay: 1,
          child: Container(
            height: 50.0,
            margin: const EdgeInsets.only(right: 13.0, left: 13.0, bottom: 26),
            child: CupertinoSearchTextField(
              placeholder: "Buscar orçamento...",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0),
              backgroundColor: Colors.white12,
              itemColor: Colors.white,
              onChanged: (String value) {
                var result = <DADOS>[];
                if (value.isNotEmpty) {
                  result = _foundUsers
                      .where((e) => e.NOMECLIENTE!.contains(value))
                      .toList();
                } else {
                  result = _foundUsers;
                }
                setState(() {
                  _foundUsers = result;
                });
              },
              onSubmitted: (String value) {
                var result = <DADOS>[];
                if (value.isNotEmpty) {
                  result = _foundUsers
                      .where((e) => e.NOMECLIENTE!.contains(value))
                      .toList();
                } else {
                  result = _foundUsers;
                }
                setState(() {
                  _foundUsers = result;
                });
              },
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: Colors.cyan[50],
            backgroundColor: bgColor,
            onRefresh: () async {
              await getInformationOrcamento();
              setState(() {
                deleteItens.clear();
                deleteVisible = false;
                checkBoxAppear = false;
              });
            },
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(
                  bottom: 170, left: 15, right: 15, top: 0),
              itemCount: _foundUsers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: ExpansionTileCard(
                    baseColor: Colors.cyan[50],
                    expandedColor: Colors.green[50],
                    leading: const CircleAvatar(
                        backgroundColor: bgColor,
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                        )),
                    title: Text(
                      "${_foundUsers[index].NOMECLIENTE}",
                      maxLines: 2,
                      style: const TextStyle(
                        color: bgColor,
                        letterSpacing: 0.5,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text("Nº orçamento: ${_foundUsers[index].ID}",
                        style: const TextStyle(
                            color: bgColor,
                            letterSpacing: 0.5,
                            fontSize: 12.0)),
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
                            "Telefone: ${_foundUsers[index].FONE}",
                            style: const TextStyle(
                              color: bgColor,
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
                              "Data do orçamento: ${_foundUsers[index].DATA}",
                              style: const TextStyle(
                                  color: bgColor,
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
                          child: Text("Status: ${_foundUsers[index].STATUS}",
                              style: const TextStyle(
                                  color: bgColor,
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
                          child: Text("Criado em: ${_foundUsers[index].DATA}",
                              style: const TextStyle(
                                  color: bgColor,
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
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                return Visibility(
                                  visible: !_foundUsers[index].checkBox!,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: SizedBox(
                                    width: 85.0,
                                    height: 52.0,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                             bgColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (!_foundUsers[index].checkBox!) {
                                          _foundUsers[index].checkBox = true;
                                          _foundUsers[index].indice = index;
                                          deleteItens.add(_foundUsers[index]);
                                          if (deleteItens.isNotEmpty) {
                                            deleteVisible = true;
                                          }
                                        }
                                        setState(() {});
                                      },
                                      child: const Column(
                                        children: <Widget>[
                                          SizedBox(height: 4),
                                          Icon(Icons.delete_outline_rounded),
                                          SizedBox(height: 2.0),
                                          Text('Excluir', style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                return SizedBox(
                                  width: 85.0,
                                  height: 52.0,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: bgColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                    ),
                                    onPressed: () {
                                      Orcamento.IDORCAMENTO =
                                          _foundUsers[index].ID;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => pg_TabOrcamento(
                                              item: _foundUsers[index]),
                                        ),
                                      ).then((value) => setState(() {
                                            try {
                                              setState(() async {
                                                await getInformationOrcamento();
                                                setState(() {
                                                  deleteItens.clear();
                                                  deleteVisible = false;
                                                  checkBoxAppear = false;
                                                });
                                              });
                                            } catch (e) {}
                                          }));
                                    },
                                    child: const Column(
                                      children: <Widget>[
                                        SizedBox(height: 4),
                                        Icon(Icons.edit),
                                        SizedBox(height: 2.0),
                                        Text('Editar', style: TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                return SizedBox(
                                  width: 85.0,
                                  height: 52.0,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: bgColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                    ),
                                    onPressed: () async {
                                      Orcamento.IDORCAMENTO = _foundUsers[index].ID;
                                      await _dialogDuplicate();
                                    },
                                    child: const Column(
                                      children: <Widget>[
                                        SizedBox(height: 4),
                                        Icon(Icons.copy),
                                        SizedBox(height: 2.0),
                                        Text('Duplicar', style: TextStyle(fontSize: 10)),
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
                );
              },
            ),
          ),
        ),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Visibility(
            visible: deleteVisible ?? true,
            child: badges.Badge(
              badgeStyle: badges.BadgeStyle(
                badgeColor: const Color.fromARGB(255, 231, 15, 87),
                borderRadius: BorderRadius.circular(40),
              ),
              badgeContent: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Center(
                  child: Text(
                    deleteItens.length.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              child: FloatingActionButton(
                heroTag: "delete",
                onPressed: _dialogDeleteBuilder,
                backgroundColor: buttonColor,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(height: he * 0.02),
          FloatingActionButton(
            heroTag: "adicionar",
            onPressed: () async {
              novo.FONE = '';
              novo.NOMECLIENTE = '';
              novo.NOMEEMPRESA = '';
              novo.ENDERECO = '';
              novo.EMAIL = '';
              novo.GERADO = '';
              novo.DATA = '';
              novo.STATUS = '';
              novo.CEP = '';
              novo.CITY = '';
              novo.BAIRRO = '';
              novo.ID = '';
              novo.RUA = '';
              Orcamento.IDORCAMENTO = '';
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => pg_TabOrcamento(item: novo)),
              ).then((value) => setState(() {
                    try {
                      setState(() async {
                        await getInformationOrcamento();
                        setState(() {
                          deleteItens.clear();
                          deleteVisible = false;
                          checkBoxAppear = false;
                        });
                      });
                    } catch (e) {
                      print(e);
                    }
                  }));
            },
            backgroundColor: buttonColor,
            child: const Icon(
              Icons.add,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
