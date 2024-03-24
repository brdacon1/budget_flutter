import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/services/http_request.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/presentations/product/product_price_creator/product_price_creator_view.dart';
import 'package:oflite/presentations/product/product_price_list/product_price_list_view.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:oflite/models/global_uid_budget.dart' as budget;
import '../../../models/items_budget.dart';
import '../../../Services/display_alert.dart';
import '../../../Services/loading_event.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
TextEditingController _searchController = TextEditingController();

class BudgetListItemsView extends StatefulWidget {
  final CustomerInfo item;
  const BudgetListItemsView({Key? key, required this.item}) : super(key: key);
  @override
  State<BudgetListItemsView> createState() => _BudgetListItemsView();
}

class _BudgetListItemsView extends State<BudgetListItemsView> {
  var orcamentos = <ItemsBudget>[];
  var deleteItens = <ItemsBudget>[];
  ItemsBudget novo = ItemsBudget();
  ConvertCoin moneyConvert = ConvertCoin();
  var displayAlert = DisplayAlert();
  var db = HttpRequest();
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  double totalProducts = 0;
  double totalServices = 0;
  double totalBudget = 0;
  int countProduct = 0;
  int countService = 0;

  @override
  initState() {
    super.initState();
    getListItens();
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
                                    moneyConvert.convertFromDouble(deleteItens[index].PRECO!),
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
                                    getFilteredData()[deleteItens[index].indice].checkBox = false;
                                    deleteItens.remove(deleteItens[index]);
                                    if (deleteItens.isEmpty) {
                                      deleteVisible = false;
                                      checkBoxAppear = false;
                                    }
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
                            setState(() {});
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
    ).then((value) async {
      if(deleteItens.isEmpty){
        getListItens();
      }
      setState(() {});
    });
  }

  Future<bool> deleteData() async {
    bool result = false;

    for (int i = 0; i < deleteItens.length; i++) {
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${widget.item.id}/ITENS")
          .doc(deleteItens[i].id)
          .delete();
    }
    result = true;
    return result;
  }

  Future<void> getListItens() async {
    orcamentos.clear();
    totalProducts = 0;
    totalServices = 0;
    totalBudget = 0;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${widget.item.id}/ITENS")
        .orderBy('CATEGORIA', descending: false)
        .get();
    List<QueryDocumentSnapshot> documents = querySnapshot.docs;
    for (var document in documents) {
      Map<String, dynamic> data = document.data() as Map<String, dynamic>;
      ItemsBudget item = ItemsBudget.fromMap(data);
      item.checkBox = false;
      item.id = document.id; // Obter o doc.id e atribuir ao item.id
      orcamentos.add(item);
    }
    for (int index = 0; index < orcamentos.length; index++) {
      double total = orcamentos[index].TOTAL!;
      if (orcamentos[index].CATEGORIA == 'Produtos') {
        totalProducts += total;
        countProduct++;
      } else if (orcamentos[index].CATEGORIA == 'Serviços') {
        totalServices += total;
        countService++;
      }
      totalBudget += total;
    }
    if(budget.VALORTOTAL != totalBudget)
    {
      budget.VALORTOTAL = totalBudget;
       await db.updateItemsDADOS();
    }


    setState(() {});
  }

  void onSearchTextChanged(String value) {
    setState(() {});
  }

  List<ItemsBudget> getFilteredData() {
    if (_searchController.text.isEmpty) {
      return orcamentos; // Retorna a lista original se não houver texto de busca
    } else {
      return orcamentos
          .where((x) => x.DESCRICAO!.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList(); // Filtra a lista original com base no texto de busca
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
            FadeAnimationWidget(
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
            FadeAnimationWidget(
              delay: 1,
              child: Container(
                height: 50.0,
                margin: const EdgeInsets.only(right: 15.0, left: 15.0, bottom: 25),
                child: CupertinoSearchTextField(
                  placeholder: "Digite a descrição do item...",
                  style:  const TextStyle(color:  Colors.white,fontWeight:FontWeight.bold, fontSize: 18.0),
                  backgroundColor:  Colors.white12,
                  itemColor: Colors.white,
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
                  setState(() {
                    deleteItens.clear();
                    deleteVisible = false;
                    checkBoxAppear = false;
                  });
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 100, left: 15, right: 15, top: 3),
                  itemCount: getFilteredData().length,
                  itemBuilder: (context, index) {
                    return  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child:
                      Theme(
                          data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
                          child: ExpansionTileCard(
                          expandedTextColor: whiteColor,
                          baseColor: secondaryColor,
                          expandedColor: secondaryColor,
                          leading: const CircleAvatar(
                            backgroundColor: bgColor,
                            child: Icon(Icons.production_quantity_limits, color: whiteColor,)),
                           title:
                           Text(
                             getFilteredData()[index].DESCRICAO!,
                          maxLines: 2,
                          style: const TextStyle(
                            color: whiteColor,
                            letterSpacing: 0.5,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Preço: ${moneyConvert.convertFromDouble(getFilteredData()[index].PRECO!)}",
                          style: const TextStyle(
                            color: whiteColor,
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
                                "Categoria: ${getFilteredData()[index].CATEGORIA}",
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
                              child: Text(
                                "Total: ${moneyConvert.convertFromDouble(getFilteredData()[index].TOTAL!)}",
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
                              child: Text(
                                "Quantidade: ${getFilteredData()[index].QTD}",
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
                              child: Text(
                                "Unidade de medida: ${getFilteredData()[index].MEDIDA}",
                                style: const TextStyle(
                                  color: whiteColor,
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
                                      visible: !getFilteredData()[index].checkBox!,
                                      maintainSize: true,
                                      maintainAnimation: true,
                                      maintainState: true,
                                      child: SizedBox(
                                        width: 85.0,
                                        height: 52.0,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: whiteColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                          ),
                                          onPressed: () {
                                            if (!getFilteredData()[index].checkBox!) {
                                              getFilteredData()[index].checkBox = true;
                                              getFilteredData()[index].selectProduct = false;
                                              getFilteredData()[index].indice = index;
                                              deleteItens.add(getFilteredData()[index]);
                                              if (deleteItens.isNotEmpty) {
                                                deleteVisible = true;
                                              }
                                            }
                                            setState(() {});
                                          },
                                          child: const Column(
                                            children: <Widget>[
                                              SizedBox(height: 4),
                                              Icon(Icons.delete_outline_rounded, color: bgColor,),
                                              SizedBox(height: 2.0),
                                              Text('Excluir', style: TextStyle(fontSize: 10, color: bgColor)),
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
                                          backgroundColor: whiteColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5.0),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProductPriceCreatorView(item: getFilteredData()[index]),
                                            ),
                                          ).then((value) async => {
                                            await getListItens(),
                                            orcamentos = getFilteredData(),
                                            setState(() {}),
                                          });
                                        },
                                        child: const Column(
                                          children: <Widget>[
                                            SizedBox(height: 4),
                                            Icon(Icons.edit, color: bgColor,),
                                            SizedBox(height: 2.0),
                                            Text('Editar', style: TextStyle(fontSize: 10, color: bgColor)),
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
                backgroundColor: buttonColor,
                child: const Icon(Icons.delete_outline_rounded, color: Colors.black,),
              ),
            ),
          ),
          SizedBox(height: he * 0.02),
          FloatingActionButton(
            heroTag: "adicionar",
            onPressed: () async {
              if(await db.getNumberItems() > 0){
                await displayAlert.listNotification(context).then((value) => {
                  if(value == "Criar novo item"){
                    budget.fromListItem = true,
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductPriceCreatorView(item: novo)),
                    ).then((value) => setState(() {
                      budget.fromListItem = false;
                      getListItens();
                    })),
                  }
                  else if(value == "Selecionar da lista de preço"){
                    budget.fromListItem = false,
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductPriceListView(item: widget.item, fromMenu: false)),
                    ).then((value) => setState(()  {
                      budget.fromListItem = false;
                      getListItens();
                    })),
                  }
                });
              }
              else{
                     budget.fromListItem = true;
                     Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProductPriceCreatorView(item: novo)),
                            ).then((value) => setState(() {
                      budget.fromListItem = false;
                            getListItens();
                     }));
                }
            },
            backgroundColor: buttonColor,
            child: const Icon(Icons.add, color: Colors.black,),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 65.0,
        color: buttonColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(padding: const EdgeInsets.only(left: 10),
              child: Text(
                "Total Serviços: ${moneyConvert.convertFromDouble(totalServices)}",
                style: const TextStyle(color: bgColor, fontWeight: FontWeight.bold,),
              ),
            ),
            Padding(padding: const EdgeInsets.only(left: 10),
              child: Text(
                "Total produtos: ${moneyConvert.convertFromDouble(totalProducts)}",
                style: const TextStyle(color: bgColor, fontWeight: FontWeight.bold,),
              ),
            ),
            Padding(padding: const EdgeInsets.only(left: 10),
              child: Text(
                "Total orçamento: ${moneyConvert.convertFromDouble(totalBudget)}",
                style: const TextStyle(color: bgColor, fontWeight: FontWeight.bold,),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





