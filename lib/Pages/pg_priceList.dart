import 'package:badges/badges.dart' as badges;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/Models/convert_coin.dart';
import 'package:oflite/Pages/pg_createProduct.dart';
import 'package:oflite/Pages/pq_subscription.dart';
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
TextEditingController _searchController = TextEditingController();

class pg_priceList  extends StatefulWidget {
  final DADOS? item;
  final bool? fromMenu;
  const pg_priceList({Key? key, this.item, this.fromMenu}) : super(key: key);
  @override
  State<pg_priceList> createState() => _pg_priceList();
}

class _pg_priceList extends State<pg_priceList>  {
  Color enabled = const Color(0xFF827F8A);
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
  var displayAlert = DisplayAlert();

  @override
  initState() {
    super.initState();
    setState(()  {
      getListItens();
    });
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
              child: Text(
                "Cancelar",
                style: GoogleFonts.heebo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _valueButtonPopup = 'OK';
                Navigator.of(context).pop(_inputValue);
              },
              child: Text(
                "OK",
                style: GoogleFonts.heebo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
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
                            "Carrinho de produtos",
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
                      height: he * 0.025,
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(right: 0, left: 0, bottom: 40),
                        itemCount: addItens.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              title: Text(
                                addItens[index].DESCRICAO!,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: whiteColor,
                                  letterSpacing: 0.5,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () async {
                                double totalPrice = 0;
                                await _showTextInputDialog().then((value) => {
                                  if (_inputValue.isNotEmpty && _valueButtonPopup != 'Cancelar')
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
                                    addItens[index].CATEGORIA.toString(),
                                    style: const TextStyle(
                                      color: whiteColor,
                                      letterSpacing: 0.5,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                  Text(
                                    addItens[index].QTD.toString(),
                                    style: const TextStyle(
                                      color: whiteColor,
                                      letterSpacing: 0.5,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                  Text(
                                    moneyConvert.convertFromDouble(addItens[index].PRECO!),
                                    style: const TextStyle(
                                      color: whiteColor,
                                      letterSpacing: 0.5,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    getFilteredData()[addItens[index].indice].selectProduct = false;
                                    addItens.remove(addItens[index]);
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: whiteColor,
                                  size: 30.0,
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
                              await displayAlert.notification(context, "Feito!",
                                  "Itens adicionados na lista do orçamento com sucesso!").then((value) => {
                                   Navigator.pop(context, true),
                              });
                              setState(() {});
                            } catch (e) {
                              alertDisplayLoading.closeLoading(context);
                              await displayAlert.notificationError(context, "Erro!", "Ocorreu um erro para adicionar os itens na lista do orçamento");
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
                              color: whiteColor,
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
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start, // Ajuste esta propriedade
                          children: deleteItens.map((item) {
                            return Card(
                              color: secondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                title: Text(
                                  item.DESCRICAO!,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: whiteColor,
                                    letterSpacing: 0.5,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.CATEGORIA.toString(),
                                      style: const TextStyle(
                                        color: whiteColor,
                                        letterSpacing: 0.5,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    Text(
                                      moneyConvert.convertFromDouble(item.PRECO!),
                                      style: const TextStyle(
                                        color: whiteColor,
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
                                      getFilteredData()[item.indice].checkBox = false;
                                      deleteItens.remove(item);
                                      if (deleteItens.isEmpty) {
                                        deleteVisible = false;
                                        checkBoxAppear = false;
                                        cheBoxAppearProduct = true;
                                      }
                                      setState(() {});
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: whiteColor,
                                      size: 23.0,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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
                              await displayAlert.notification(context, "Feito!", "Itens removidos com sucesso!");
                              setState(() {});
                            } catch (e) {
                              alertDisplayLoading.closeLoading(context);
                              await displayAlert.notificationError(context, "Erro!", "Ocorreu um erro ao remover os itens.");
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
      final objectListItens = ObjectListItens.fromMap(doc.data());
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
    setState(() {});
    return List<ObjectListItens>.from(orcamentos);
  }

  void onSearchTextChanged(String value) {
    setState(() {});
  }

  List<ObjectListItens> getFilteredData() {
    if (_searchController.text.isEmpty) {
      return orcamentos;
    } else {
      return orcamentos
          .where((x) => x.DESCRICAO!.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }
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
                  onTap: () async {
                    setState(() {});
                    if(addItens.isEmpty) {
                      Navigator.pop(context, true);
                    } else {
                      await displayAlert.notificationWarning(context, "Ops!", "Você tem itens no carrinho. "
                          "Por favor, escolha entre esvaziar o carrinho ou adicionar esses itens ao orçamento.");
                    }
                  },
                  child: Container(
                    alignment: Alignment.topLeft,
                    margin: EdgeInsets.only(left: we * 0.032),
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
                margin: EdgeInsets.only(left: we * 0.04),
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
              height: he * 0.02,
            ),
            FadeAnimation(
              delay: 1,
              child: Container(
                height: 50.0,
                margin: const EdgeInsets.only(right: 17.0, left: 17.0, bottom: 25),
                child: CupertinoSearchTextField(
                  placeholder: "Digite a descrição do item...",
                  style:  const TextStyle(color:  Colors.white,fontWeight:FontWeight.bold, fontSize: 18.0),
                  backgroundColor:  Colors.white12,
                  itemColor: whiteColor,
                  controller: _searchController,
                  onChanged: onSearchTextChanged,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Colors.cyan[50],
                backgroundColor: bgColor,
                onRefresh: () async {
                  await getListItens();
                  setState(() {});
                },
                child:ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 160, left: 15, right: 15, top: 10),
                  itemCount: getFilteredData().length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        title: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${getFilteredData()[index].DESCRICAO}",
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: whiteColor,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getFilteredData()[index].CATEGORIA.toString(),
                                style: const TextStyle(
                                  color: whiteColor,
                                  letterSpacing: 0,
                                  fontSize: 12.0,
                                ),
                              ),
                              Text(
                                moneyConvert.convertFromDouble(getFilteredData()[index].PRECO!),
                                style: const TextStyle(
                                  color: whiteColor,
                                  letterSpacing: 0,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onLongPress: () {
                          checkBoxAppear = !checkBoxAppear;
                          cheBoxAppearProduct = !checkBoxAppear;
                          addItens.clear();
                          if (!checkBoxAppear) {
                            for (int i = 0; i < getFilteredData().length; i++) {
                              getFilteredData()[i].checkBox = false;
                              getFilteredData()[i].selectProduct = false;
                            }
                            deleteItens.clear();
                            deleteVisible = false;
                          }
                          setState(() {});
                        },
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PgCreateProduct(item: getFilteredData()[index])),
                          ).then((value) async => {
                            await getListItens(),
                            setState(() {}),
                          });
                        },
                        trailing: Transform.scale(
                          scale: 1.7,
                          child: Visibility(
                            visible: !(widget.fromMenu ?? false) && cheBoxAppearProduct,
                            child: Checkbox(
                              side: const BorderSide(
                                color: whiteColor,
                              ),
                              checkColor:  bgColor,
                              activeColor: whiteColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                              value: getFilteredData()[index].selectProduct,
                              onChanged: (bool? newValue) async {
                                double totalPrice = 0;
                                if (getFilteredData()[index].selectProduct == false) {
                                  await _showTextInputDialog().then((value) => {
                                    if (_inputValue.isNotEmpty && _valueButtonPopup != 'Cancelar') {
                                      totalPrice = double.parse(_inputValue.replaceAll(',', '.')) * getFilteredData()[index].PRECO!,
                                      getFilteredData()[index].selectProduct = true,
                                      getFilteredData()[index].indice = index,
                                      getFilteredData()[index].QTD = double.parse(_inputValue.replaceAll(',', '.')),
                                      getFilteredData()[index].IDPRODUCT = getFilteredData()[index].id,
                                      getFilteredData()[index].TOTAL = totalPrice,
                                      addItens.add(getFilteredData()[index]),
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
                              side: const BorderSide(
                                color: whiteColor,
                              ),
                              checkColor:  bgColor,
                              activeColor: whiteColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                              value: getFilteredData()[index].checkBox,
                              onChanged: (bool? newValue) async {
                                if (getFilteredData()[index].checkBox == false) {
                                  cheBoxAppearProduct = false;
                                  getFilteredData()[index].checkBox = true;
                                  getFilteredData()[index].selectProduct = false;
                                  getFilteredData()[index].indice = index;
                                  deleteItens.add(getFilteredData()[index]);
                                  if (deleteItens.length == 1) {
                                    deleteVisible = true;
                                  }
                                }
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
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
            visible: !(widget.fromMenu ?? false) && !(deleteVisible),
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
              ),
            ),
          ),
          Visibility(
            visible: deleteVisible,
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
              if(!UID.AutoRenewing! && getFilteredData().length > 15) {
                await displayAlert.notificationError(context, "Erro!", "Você não possuí o plano premium onde é possível cadastrar produtos ilimitados").then((value) => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => pg_subscription()),
                  ),
                });

              } else{
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PgCreateProduct(item: novo)),
                ).then((value) async => {
                  await getListItens(),
                  setState(() {}),
                });
              }
            },
            backgroundColor: const Color(0xFF0DF5E4),
            child: const Icon(Icons.add, color: Colors.black,),
          ),
        ],
      ),
    );
  }
}

