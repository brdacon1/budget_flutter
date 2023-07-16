import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/Models/convert_coin.dart';
import 'package:oflite/Pages/pg_PopUp.dart';
import 'package:oflite/Pages/pg_priceList.dart';
import 'package:oflite/anmition/fadeanimation.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/constants.dart';
import '../Objetos/DADOS.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import '../Objetos/ObjectListItens.dart';
import '../Services/display_alert.dart';
import '../Services/loading_event.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

class ListaItensOrcamento extends StatefulWidget {
  final DADOS item;
  const ListaItensOrcamento({Key? key, required this.item}) : super(key: key);
  @override
  State<ListaItensOrcamento> createState() => _ListaItensOrcamento();
}

class _ListaItensOrcamento extends State<ListaItensOrcamento> {
  var orcamentos = <ObjectListItens>[];
  var _foundUsers = <ObjectListItens>[];
  var deleteItens = <ObjectListItens>[];
  ObjectListItens novo = ObjectListItens();
  convert_coin moneyConvert = convert_coin();
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool deleteVisible = false;
  bool checkBoxAppear = false;

  @override
  initState() {
    super.initState();
    try{
      setState(()  async {
        await getListItens();
        setState(() {
          _foundUsers = orcamentos;
        });
      });
    }
    catch (e){
    }
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
                        padding: const EdgeInsets.only(right: 0, left: 0, bottom: 40),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            height: 110,
                            child: Card(
                              color: Colors.cyan[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                title: Text(
                                  deleteItens[index].DESCRICAO!,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: bgColor,
                                    letterSpacing: 0.5,
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Status:   ${deleteItens[index].CATEGORIA}",
                                      style: const TextStyle(
                                        color: bgColor,
                                        letterSpacing: 0.5,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    Text(
                                      "Medida:  ${deleteItens[index].MEDIDA}",
                                      style: const TextStyle(
                                        color: bgColor,
                                        letterSpacing: 0.5,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    Text(
                                      "Preço:     ${moneyConvert.convertFromDouble(deleteItens[index].PRECO!)}",
                                      style: const TextStyle(
                                        color: bgColor,
                                        letterSpacing: 0.5,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Transform.scale(
                                  scale: 1.7,
                                  alignment: Alignment.topCenter,
                                  child: GestureDetector(
                                    onTap: () {
                                      orcamentos[deleteItens[index].indice].checkBox = false;
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

                            setState(() {});
                          },
                          style: TextButton.styleFrom(
                                 backgroundColor: const Color(0xFF0DF5E4),
                                 padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 70),
                                 shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(30.0)
                                 )
                          ),
                          child: Text("EXCLUIR ITENS",style: GoogleFonts.heebo(
                            color: Colors.black,
                            letterSpacing: 0.5,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          )
                      ),
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
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${widget.item.ID}/ITENS")
          .doc(deleteItens[i].id)
          .delete();
      if (i == count) {
        deleteItens.clear();
        orcamentos.clear();
        deleteVisible = false;
        await getListItens();
        _foundUsers = orcamentos;
      }
    }

    result = true;
    return result;
  }

  Future<List<ObjectListItens>> getListItens() async {
    _foundUsers.clear();
    orcamentos.clear();
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${widget.item.ID}/ITENS")
        .orderBy('CATEGORIA', descending: false)
        .get();
    List<QueryDocumentSnapshot> documents = querySnapshot.docs;
    for (var document in documents) {
      Map<String, dynamic> data = document.data() as Map<String, dynamic>;
      ObjectListItens item = ObjectListItens.fromMap(data);
      item.checkBox = false;
      item.id = document.id; // Obter o doc.id e atribuir ao item.id
      orcamentos.add(item);
    }
    return orcamentos;
  }


  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
              SizedBox(
                height: he * 0.07,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                  GestureDetector(
                    onTap: (){
                      Navigator.pop(context, true);
                    },
                    child: Container(
                      alignment: Alignment.topLeft,
                      margin: EdgeInsets.only(left: we * 0.028),
                      child: const Icon(Icons.arrow_back_outlined,color: Colors.white,size: 35.0,),
                    ),
                  ),
                ],
            ),
            SizedBox(
              height: he * 0.02,
            ),
            FadeAnimation(
              delay: 1,
              child: Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: we * 0.035),
                child: Text("Itens orçamentos",style: GoogleFonts.heebo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    letterSpacing: 1
                ),
                ),
              ),
            ),
            SizedBox(
              height: he * 0.02,
            ),
            FadeAnimation(
              delay: 1,
              child: Container(
                height: 50.0,
                margin: const EdgeInsets.only(right: 15.0, left: 15.0, bottom: 25),
                child: CupertinoSearchTextField(
                  placeholder: "Buscar Itens...",
                  style:  const TextStyle(color:  Colors.white,fontWeight:FontWeight.bold, fontSize: 18.0),
                  backgroundColor:  Colors.white12,
                  itemColor: Colors.white,
                  onChanged: (String value) {
                    var result = <ObjectListItens>[];
                    if (value.isNotEmpty) {
                       result = orcamentos.where((e) => e.DESCRICAO!.contains(value)).toList();
                    } else {
                       result  = orcamentos;
                    }
                    setState(() {
                       _foundUsers = result;
                    });
                  },
                  onSubmitted: (String value) {
                    var result = <ObjectListItens>[];
                    if (value.isNotEmpty) {
                        result = orcamentos.where((e) => e.DESCRICAO!.contains(value)).toList();
                    } else {
                        result  = orcamentos;
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
                  await getListItens();
                  setState(() {
                    deleteItens.clear();
                    deleteVisible = false;
                    checkBoxAppear = false;
                  });
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 100, left: 15, right: 15, top: 3),
                  itemCount: _foundUsers.length,
                  itemBuilder: (context, index) {
                    return  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: ExpansionTileCard(
                        baseColor: Colors.cyan[50],
                        expandedColor: Colors.blue[50],
                        leading: const CircleAvatar(
                            backgroundColor: bgColor,
                            child: Icon(Icons.production_quantity_limits, color: Colors.white,)),
                        title:
                        Text(
                          _foundUsers[index].DESCRICAO!,
                          maxLines: 2,
                          style: const TextStyle(
                            color: bgColor,
                            letterSpacing: 0.5,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Preço: ${moneyConvert.convertFromDouble(_foundUsers[index].PRECO!)}",
                          style: const TextStyle(
                            color: bgColor,
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
                                "Categoria: ${_foundUsers[index].CATEGORIA}",
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
                                "Total: ${moneyConvert.convertFromDouble(_foundUsers[index].TOTAL!)}",
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
                                "Quantidade: ${_foundUsers[index].QTD}",
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
                                "Unidade de medida: ${_foundUsers[index].MEDIDA}",
                                style: const TextStyle(
                                  color: bgColor,
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
                                      visible: !_foundUsers[index].checkBox!,
                                      maintainSize: true,
                                      maintainAnimation: true,
                                      maintainState: true,
                                      child: SizedBox(
                                        width: 85.0,
                                        height: 52.0,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: bgColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                          ),
                                          onPressed: () {
                                            if (!_foundUsers[index].checkBox!) {
                                              _foundUsers[index].checkBox = true;
                                              _foundUsers[index].selectProduct = false;
                                              _foundUsers[index].indice = index;
                                              deleteItens.add(orcamentos[index]);
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
                                              Text('Excluir'),
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
                                          backgroundColor: bgColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5.0),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => pg_PopUp(item: _foundUsers[index]),
                                            ),
                                          ).then((value) async => {
                                            await getListItens(),
                                            _foundUsers = orcamentos,
                                            setState(() {}),
                                          });
                                        },
                                        child: const Column(
                                          children: <Widget>[
                                            SizedBox(height: 4),
                                            Icon(Icons.edit),
                                            SizedBox(height: 2.0),
                                            Text('Editar'),
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
          ]
      ),
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
                child: Center( child: Text(
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
                child: const Icon(Icons.delete_outline_rounded, color: Colors.black,),
              ),
            ),
          ),
          SizedBox(height: he * 0.02),
          FloatingActionButton(
            heroTag: "adicionar",
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => pg_priceList(item: widget.item, fromMenu: false,)),
              ).then((value) => setState(() {
                try{
                  setState(()  async {
                    await getListItens();
                    setState(() {
                      _foundUsers = orcamentos;
                    });
                  });
                }
                catch (e){
                  print(e);
                }
              }));
            },
            backgroundColor: buttonColor,
            child: const Icon(Icons.add, color: Colors.black,),
          ),
        ],
      ),
    );
  }
}




