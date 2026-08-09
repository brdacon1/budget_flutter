import 'package:badges/badges.dart' as badges;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/common/widgets/modals/items_list_bottom_modal_widget.dart';
import 'package:oflite/common/widgets/modals/text_input_bottom_modal_widget.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/presentations/product/model/product_price_model.dart';
import 'package:oflite/presentations/product/product_price_creator/product_price_creator_view.dart';
import 'package:oflite/presentations/subscription/subscription_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/common/constants/constants.dart';
import '../../../models/customer_info.dart';
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:oflite/models/global_uid_budget.dart' as budget;
import '../../../models/items_budget.dart';
import '../../../Services/display_alert.dart';
import '../../../Services/loading_event.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
TextEditingController _searchController = TextEditingController();

class ProductPriceListView  extends StatefulWidget {
  final CustomerInfo? item;
  final bool? fromMenu;
  const ProductPriceListView({Key? key, this.item, this.fromMenu}) : super(key: key);

  @override
  State<ProductPriceListView> createState() => _ProductPriceListView();
}

class _ProductPriceListView extends State<ProductPriceListView>  {
  Color enabled = const Color(0xFF827F8A);
  var orcamentos = <ItemsBudget>[];
  var deleteItens = <ItemsBudget>[];
  var addItens = <ItemsBudget>[];
  ItemsBudget novo = ItemsBudget();
  ConvertCoin moneyConvert = ConvertCoin();
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
          .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${budget.IDORCAMENTO}/ITENS")
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
    final value = await showTextInputBottomModal(
      context,
      title: 'Defina quantidade',
      hintText: 'Digite a quantidade',
    );
    setState(() {
      _inputValue = value ?? '';
      _valueButtonPopup = (value == null) ? 'Cancelar' : 'OK';
    });
  }

  Future<void> _dialogBuilder() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemsListBottomModalWidget(
        title: 'Carrinho de produtos',
        items: addItens,
        moneyConvert: moneyConvert,
        buttonLabel: 'ADICIONAR',
        onRemove: (item, index) {
          setState(() {
            getFilteredData()[item.indice].selectProduct = false;
            addItens.remove(item);
          });
        },
        onItemTap: (item, index) async {
          await _showTextInputDialog();
          if (_inputValue.isNotEmpty && _valueButtonPopup != 'Cancelar') {
            double totalPrice = int.parse(_inputValue) * item.PRECO!;
            item.indice = index;
            item.QTD = double.parse(_inputValue.replaceAll(',', '.'));
            item.TOTAL = totalPrice;
            _inputValue = '';
            _valueButtonPopup = '';
            setState(() {});
          }
        },
        onButtonPressed: () async {
          var alertDisplayLoading = LoadingEvent();
          await alertDisplayLoading.alertLoading(context);
          try {
            await salvaItensList();
            addItens.clear();
            await getListItens();
            alertDisplayLoading.closeLoading(context);
            if (context.mounted) {
              Navigator.pop(context, true);
              await displayAlert.notification(
                context,
                'Feito!',
                'Itens adicionados na lista do orçamento com sucesso!',
              );
            }
            setState(() {});
          } catch (e) {
            alertDisplayLoading.closeLoading(context);
            if (context.mounted) {
              await displayAlert.notificationError(
                  context, 'Erro!', 'Ocorreu um erro para adicionar os itens na lista do orçamento');
            }
            setState(() {});
          }
        },
      ),
    ).then((value) {
      setState(() {});
    });
  }

  Future<void> _dialogDeleteBuilder() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemsListBottomModalWidget(
        title: 'Remover produtos',
        items: deleteItens,
        moneyConvert: moneyConvert,
        buttonLabel: 'EXCLUIR ITENS',
        onRemove: (item, index) {
          getFilteredData()[item.indice].checkBox = false;
          deleteItens.remove(item);
          if (deleteItens.isEmpty) {
            deleteVisible = false;
            checkBoxAppear = false;
            cheBoxAppearProduct = true;
          }
          setState(() {});
        },
        onButtonPressed: () async {
          var alertDisplayLoading = LoadingEvent();
          await alertDisplayLoading.alertLoading(context);
          try {
            await DeleteDados();
            deleteItens.clear();
            deleteVisible = false;
            checkBoxAppear = false;
            alertDisplayLoading.closeLoading(context);
            if (context.mounted) {
              await displayAlert.notification(context, 'Feito!', 'Itens removidos com sucesso!');
            }
            setState(() {});
          } catch (e) {
            alertDisplayLoading.closeLoading(context);
            if (context.mounted) {
              await displayAlert.notificationError(context, 'Erro!', 'Ocorreu um erro ao remover os itens.');
            }
            setState(() {});
          }
        },
      ),
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
          .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/PRICELIST/")
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

  Future<List<ItemsBudget>> getListItens() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user.toString()}/USERS/${UID.user.toString()}/PRICELIST")
        .get();

    final list = querySnapshot.docs.map<ItemsBudget>((doc) {
      final objectListItens = ItemsBudget.fromMap(doc.data());
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
    return List<ItemsBudget>.from(orcamentos);
  }

  void onSearchTextChanged(String value) {
    setState(() {});
  }

  List<ItemsBudget> getFilteredData() {
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
            FadeAnimationWidget(
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
            FadeAnimationWidget(
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
                            MaterialPageRoute(
                                builder: (context) => ProductPriceCreatorView(
                                    item: ProductPriceModel.fromItemsBudget(
                                        getFilteredData()[index]))),
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
              if(!UID.autoRenewing! && getFilteredData().length > 15) {
                await displayAlert.notificationError(context, "Erro!", "Você não possuí o plano premium onde é possível cadastrar produtos ilimitados").then((value) => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SubscriptionView()),
                  ),
                });

              } else{
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProductPriceCreatorView(
                          item: ProductPriceModel.fromItemsBudget(novo))),
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

