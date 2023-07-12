import 'package:badges/badges.dart' as badges;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/Models/convert_coin.dart';
import 'package:oflite/Pages/pg_PopUp.dart';
import 'package:oflite/anmition/fadeanimation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/constants.dart';
import '../Objetos/DADOS.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import 'package:oflite/Objetos/globalUIDOrcamento.dart' as Orcamento;
import '../Objetos/ObjectListItens.dart';
import '../Services/display_alert.dart';
import '../Services/loading_event.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

class pg_priceList  extends StatefulWidget {
  final DADOS item;
  const pg_priceList({Key? key, required this.item}) : super(key: key);
  @override
  State<pg_priceList> createState() => _pg_priceList();
}

class _pg_priceList extends State<pg_priceList>  {
  Color enabled = const Color(0xFF827F8A);
  Color backgroundColor = const Color(0xFF1F1A30);
  var orcamentos = <ObjectListItens>[];
  var deleteItens = <ObjectListItens>[];
  var addItens = <ObjectListItens>[];
  ObjectListItens novo = ObjectListItens();
  convert_coin moneyConvert = convert_coin();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  bool cheBoxAppearProduct = true;


  @override
  initState() {
    super.initState();
    try{
      setState(()  async {
        await getListItens().then((value) => {
              setState(() {}),
        });
      });
    }
    catch (e){
    }
  }

  Future <bool> salvaItensList() async {
    bool result = false;
    int count = addItens.length - 1;
    for(int i = 0; i< addItens.length; i++)
    {
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/ITENS")
          .doc(addItens[i].id)
          .set({'CATEGORIA': addItens[i].CATEGORIA,
                'DESCRICAO' : addItens[i].DESCRICAO,
                'PRECO' : addItens[i].PRECO,
                'QTD' : addItens[i].QTD,
                'MEDIDA' : addItens[i].MEDIDA,
                'TOTAL' : addItens[i].TOTAL,
                'IDPRODUCT': addItens[i].id,})
          .then((value) async {
        if(i == count)
        {
          setState(() {
            addItens.clear();
            deleteItens.clear();
            orcamentos.clear();
            deleteVisible = false;
            cheBoxAppearProduct = true;
          });
          await getListItens();
        }
      });
    }
    return result;
  }

  String _inputValue = '';
  String _valueButtonPopup = '';

  Future<void> _showTextInputDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Defina quantidade'),
          content: TextField(
            onChanged: (value) {
              setState(() {
                _inputValue = value;
              });
            },
            keyboardType: TextInputType.number,
            maxLength: 10,
            decoration: const InputDecoration(
              hintText: 'Digite a quantidade',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _valueButtonPopup = 'Cancelar';
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _valueButtonPopup = 'OK';
                Navigator.of(context).pop(_inputValue);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilder() {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(19),
          backgroundColor: const Color(0xFF1F1A30),
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
                              "Carrinho de produtos",
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
                        padding: const EdgeInsets.only(right: 0, left: 0, bottom: 40),
                        itemCount: addItens.length,
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
                                  "Descrição: ${addItens[index].DESCRICAO}",
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: Color(0xFF1F1A30),
                                    letterSpacing: 0.5,
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () async {
                                    double totalPrice = 0;
                                    await _showTextInputDialog().then((value) => {
                                      if(_inputValue.isNotEmpty && _valueButtonPopup != 'Cancelar')
                                        {
                                          totalPrice = int.parse(_inputValue) * addItens[index].PRECO!,
                                          addItens[index].indice = index,
                                          addItens[index].QTD = double.parse(_inputValue.replaceAll(',', '.')),
                                          addItens[index].TOTAL = totalPrice,
                                          _inputValue = '',
                                          _valueButtonPopup = '',
                                        }
                                    });
                                },
                                subtitle: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Status:   ${addItens[index].CATEGORIA}",
                                      style: const TextStyle(
                                        color: Color(0xFF1F1A30),
                                        letterSpacing: 0.5,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    Text(
                                      "Medida:  ${addItens[index].MEDIDA}",
                                      style: const TextStyle(
                                        color: Color(0xFF1F1A30),
                                        letterSpacing: 0.5,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    Text(
                                      "Preço:     R\$ ${moneyConvert.convertFromDouble(addItens[index].PRECO!)}",
                                      style: const TextStyle(
                                        color: Color(0xFF1F1A30),
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
                                      setState(() {
                                        orcamentos[addItens[index].indice]
                                            .selectProduct = false;
                                            addItens.remove(addItens[index]);
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Color(0xFF1F1A30),
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
                              await salvaItensList();
                              addItens.clear();
                              await getListItens();

                              alertDisplayLoading.closeLoading(context);
                              await displayAlert.notification(context, "Tudo Certo!", "Orçamentos removidos com sucesso!");
                              setState(() {});
                            } catch (e) {
                              alertDisplayLoading.closeLoading(context);
                              await displayAlert.notificationError(context, "Erro!", "Ocorreu um erro ao remover os orçamentos.");
                            }
                            setState(() {});
                          },
                          style:  TextButton.styleFrom(
                              backgroundColor: const Color(0xFF0DF5E4),
                              padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 90),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0)
                              )
                          ),
                          child: Text("ADICIONAR",style: GoogleFonts.heebo(
                            color: Colors.black,
                            letterSpacing: 0,
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

  Future<void> _dialogDeleteBuilder() {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(19),
          backgroundColor: const Color(0xFF1F1A30),
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
                                  "Descrição: ${deleteItens[index].DESCRICAO}",
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: Color(0xFF1F1A30),
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
                                        color: Color(0xFF1F1A30),
                                        letterSpacing: 0.5,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    Text(
                                      "Medida:  ${deleteItens[index].MEDIDA}",
                                      style: const TextStyle(
                                        color: Color(0xFF1F1A30),
                                        letterSpacing: 0.5,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    Text(
                                      "Preço:     ${moneyConvert.convertFromDouble(deleteItens[index].PRECO!)}",
                                      style: const TextStyle(
                                        color: Color(0xFF1F1A30),
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
                                        cheBoxAppearProduct = true;
                                      }
                                      setState(() {});
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Color(0xFF1F1A30),
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
                              await DeleteDados();
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
                          style:  TextButton.styleFrom(
                              backgroundColor: buttonColor,
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

  Future <bool> DeleteDados() async {
    bool result = false;
    int count = deleteItens.length - 1;
    for(int i = 0; i< deleteItens.length; i++)
    {
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/PRICELIST/")
          .doc(deleteItens[i].id)
          .delete().then((value) async {
        if(i == count)
        {
          setState(() {
            addItens.clear();
            deleteItens.clear();
            orcamentos.clear();
            deleteVisible = false;
            cheBoxAppearProduct = true;
          });
          await getListItens();
          setState(() {
          });
        }
      });
    }
    return result;
  }

  Future<List<ObjectListItens>> getListItens() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER.toString()}/USERS/${UID.USER.toString()}/PRICELIST")
        .get();

    final list = querySnapshot.docs.map<ObjectListItens>((doc) {
      final objectListItens = ObjectListItens.fromMap(doc.data()!);
      objectListItens.id = doc.id;
      objectListItens.checkBox = false;
      objectListItens.selectProduct = false;
      return objectListItens;
    }).toList();

    for (var item in addItens) {
      final index = list.indexWhere((listItem) => listItem.id == item.id);
      if (index != -1) {
        list[index].checkBox = false;
        list[index].indice = index;
        list[index].selectProduct = true;
      }
    }

    for (var item in deleteItens) {
      final index = list.indexWhere((listItem) => listItem.id == item.id);
      if (index != -1) {
        list[index].checkBox = true;
        list[index].indice = index;
        list[index].selectProduct = false;
      }
    }

    orcamentos = [];
    orcamentos = list;
    return List<ObjectListItens>.from(orcamentos);
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFF1F1A30),
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
                    margin: EdgeInsets.only(left: we * 0.04),
                    child: const Icon(Icons.arrow_back_outlined,color: Colors.white,size: 35.0,),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: he * 0.03,
            ),
            FadeAnimation(
              delay: 1,
              child: Container(
                margin: const EdgeInsets.only(right: 140.0),
                child: Text("Lista de preço",style: GoogleFonts.heebo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: 2
                ),
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
                margin: const EdgeInsets.only(right: 20.0, left: 20.0, bottom: 25),
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
                  },
                  onSubmitted: (String value) {
                    var result = <ObjectListItens>[];
                    if (value.isNotEmpty) {
                      result = orcamentos.where((e) => e.DESCRICAO!.contains(value)).toList();
                    } else {
                      result  = orcamentos;
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Colors.cyan[50],
                backgroundColor: const Color(0xFF1F1A30),
                onRefresh: () async {
                  await getListItens();
                  setState(() {});
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 160, left: 15, right: 15, top: 10),
                  itemCount: orcamentos.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      height: 110,
                      child: Card(
                        color: Colors.cyan[50],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)
                        ),
                        child:
                        ListTile(
                          title:  Padding(
                            padding: const EdgeInsets.only(bottom: 5, top: 5.3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "${orcamentos[index].DESCRICAO}",
                                      maxLines: 2,
                                      style: const TextStyle(
                                        color: Color(0xFF1F1A30),
                                        letterSpacing: 0,
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Padding( padding: const EdgeInsets.only(bottom: 5,),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Categoria:   ${orcamentos[index].CATEGORIA}", style: const TextStyle(color: Color(0xFF1F1A30),
                                        letterSpacing: 0,
                                        fontSize: 12.0)),
                                    Text("Medida:       ${orcamentos[index].MEDIDA}", style: const TextStyle(color: Color(0xFF1F1A30),
                                        letterSpacing: 0,
                                        fontSize: 12.0)),
                                    Text("Preço:          ${moneyConvert.convertFromDouble(orcamentos[index].PRECO!)}", style: const TextStyle(color: Color(0xFF1F1A30),
                                        letterSpacing: 0,
                                        fontSize: 12.0)),
                                  ])
                          ),
                          onLongPress: () {
                            checkBoxAppear = !checkBoxAppear;
                            cheBoxAppearProduct = !checkBoxAppear;
                            addItens.clear();
                            if (!checkBoxAppear) {
                              for (int i = 0; i < orcamentos.length; i++) {
                                orcamentos[i].checkBox = false;
                                orcamentos[i].selectProduct = false;
                              }
                              deleteItens.clear();
                              deleteVisible = false;
                            }
                            setState(() {});
                          },
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => pg_PopUp(item: orcamentos[index])),
                            ).then((value) async => {
                              await getListItens(),
                              setState(() {}),
                            });
                          },
                          trailing: Transform.scale(
                            scale: 1.7,
                            child: Visibility(
                              visible: cheBoxAppearProduct,
                              child: Checkbox(
                                value:  orcamentos[index].selectProduct,
                                side: const BorderSide(
                                  color: Color(0xFF1F1A30),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                                checkColor:  Colors.white,
                                activeColor: const Color(0xFF1F1A30),
                                onChanged: (bool? newValue) async
                                {
                                  double totalPrice = 0;
                                  if(orcamentos[index].selectProduct == false)
                                  {
                                    await _showTextInputDialog().then((value) => {
                                      if(_inputValue.isNotEmpty && _valueButtonPopup != 'Cancelar')
                                        {
                                          totalPrice = double.parse(_inputValue.replaceAll(',', '.')) * orcamentos[index].PRECO!,
                                          orcamentos[index].selectProduct = true,
                                          orcamentos[index].indice = index,
                                          orcamentos[index].QTD = double.parse(_inputValue.replaceAll(',', '.')),
                                          orcamentos[index].IDPRODUCT = orcamentos[index].id,
                                          orcamentos[index].TOTAL = totalPrice,
                                          addItens.add(orcamentos[index]),
                                          _inputValue = '',
                                          _valueButtonPopup = '',
                                        }
                                    });
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          leading: Transform.scale(
                            scale: 1.6,
                            child: Visibility(
                              visible: checkBoxAppear,
                              child: Checkbox(
                                value:  orcamentos[index].checkBox,
                                side: const BorderSide(
                                  color: Color(0xFF1F1A30),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                                checkColor:  Colors.white,
                                activeColor: const Color(0xFF1F1A30),
                                onChanged: (bool? newValue) async {
                                  if(orcamentos[index].checkBox == false)
                                  {
                                    cheBoxAppearProduct = false;
                                    orcamentos[index].checkBox = true;
                                    orcamentos[index].selectProduct = false;
                                    orcamentos[index].indice = index;
                                    deleteItens.add(orcamentos[index]);
                                    if(deleteItens.length == 1)
                                    {
                                      deleteVisible = true;
                                    }
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ]
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Visibility(
            visible: !deleteVisible ?? true,
            child: badges.Badge(
              badgeStyle: badges.BadgeStyle(
                badgeColor: const Color.fromARGB(255, 231, 15, 87),
                borderRadius: BorderRadius.circular(40),
              ),
              badgeContent: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Center(
                  child: Text(
                    addItens.length.toString(),
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
                heroTag: "car",
                onPressed: _dialogBuilder,
                backgroundColor: const Color(0xFF0DF5E4),
                child: const Icon(Icons.shopping_cart_outlined, color: Colors.black,),
              )
            ),
          ),
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
                 backgroundColor: const Color(0xFF0DF5E4),
                 child: const Icon(Icons.delete_outline_rounded, color: Colors.black,),
               ),
             ),
          ),
          SizedBox(height: he * 0.02),
          FloatingActionButton(
            heroTag: "adicionar",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => pg_PopUp(item: novo)),
              ).then((value) async => {
                  await getListItens(),
                  setState(() {}),
              });
            },
            backgroundColor: const Color(0xFF0DF5E4),
            child: const Icon(Icons.add, color: Colors.black,),
          ),
        ],
      ),
    );
  }
}

