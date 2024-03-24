import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/presentations/budget/budget_tab/budget_tab_view.dart';
import 'package:oflite/presentations/subscription/subscription_view.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/http_request.dart';
import 'package:oflite/services/loading_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/models/global_uid_budget.dart' as budget;
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:badges/badges.dart' as badges;
import '../../../Services/convert_coin.dart';
import '../../../common/constants/constants.dart';
import '../../../models/customer_info.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
TextEditingController _searchController = TextEditingController();

class BudgetListView extends StatefulWidget {
  const BudgetListView({Key? key}) : super(key: key);

  @override
  State<BudgetListView> createState() => _BudgetListView();
}

class _BudgetListView extends State<BudgetListView> {
  CustomerInfo customerBudget = CustomerInfo();
  Color enabled = const Color(0xFF827F8A);
  final _foundUsers = <CustomerInfo>[];
  final deleteItens = <CustomerInfo>[];
  CustomerInfo novo = CustomerInfo();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  var displayAlert = DisplayAlert();
  ConvertCoin moneyConvert = ConvertCoin();
  BannerAd? _bannerAd;
  final String _adUnitId = 'ca-app-pub-5106035309089315/6550502888';
  final String _adUnitIdInterstitialAd = 'ca-app-pub-5106035309089315/6467754164';
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  @override
  initState() {
    budget.IDORCAMENTO = '';
    _loadAd();
    _loadInterstitialAd();
    initialScreen();
    super.initState();
  }

  void initialScreen() async {
    await getInformationOrcamento();
    setState(() {});
  }

  Future<void> _duplicateEvent(bool clientData, bool quoteItems, bool comments)async {
      var db = HttpRequest();
      String? ID = budget.IDORCAMENTO;
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);
      if(clientData) {
        await db.getInformationOrcamento1().then((value) => {
          if(value.customerName!.isNotEmpty)
            {
              customerBudget.customerName = value.customerName,
              customerBudget.phone = value.phone,
              customerBudget.status = value.status,
              customerBudget.email = value.email,
              customerBudget.address = value.address,
              customerBudget.generated = value.generated,
              customerBudget.companyName = value.companyName,
              customerBudget.zip = value.zip,
              customerBudget.street = value.street,
              customerBudget.city = value.city,
              customerBudget.neighborhood = value.neighborhood,
              customerBudget.data = formatted,
              customerBudget.id = DateTime.now().millisecondsSinceEpoch.toString(),
              customerBudget.totalValue = value.totalValue,
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
          customerBudget.customerName = "Duplicado de: ${ID}";
          customerBudget.phone = "";
          customerBudget.status = "";
          customerBudget.email = "";
          customerBudget.address = "";
          customerBudget.generated = "";
          customerBudget.companyName = "";
          customerBudget.zip = "";
          customerBudget.street = "";
          customerBudget.city = "";
          customerBudget.neighborhood = "";
          customerBudget.data = formatted;
          customerBudget.id = DateTime.now().millisecondsSinceEpoch.toString();

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
                                    "Cliente: ${deleteItens[index].customerName}",
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
                                          "Nº orçamento: ${deleteItens[index].id}",
                                          style: const TextStyle(
                                              color: bgColor,
                                              letterSpacing: 0.5,
                                              fontSize: 12.0)),
                                      Text(
                                          "Status: ${deleteItens[index].status}",
                                          style: const TextStyle(
                                              color: bgColor,
                                              letterSpacing: 0.5,
                                              fontSize: 12.0)),
                                      Text(
                                          "Criado em: ${deleteItens[index].data}",
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
                                      getFilteredData()[deleteItens[index].index]
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
                            "EXCLUIR TODOS",
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
          .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
          .doc(deleteItens[i].id)
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

  Future<List<CustomerInfo>> getInformationOrcamento() async {
    int index = 0;
    _foundUsers.clear();

    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
        .orderBy('ID', descending: true)
        .get();

    for (var questionTmp in querySnapshot.docs) {
      final data = questionTmp.data();
      _foundUsers.add(CustomerInfo.fromMap(data));
      _foundUsers[index].checkBox = false;
      index++;
    }

    return _foundUsers;
  }

  void onSearchTextChanged(String value) {
    setState(() {});
  }

  List<CustomerInfo> getFilteredData() {
    if (_searchController.text.isEmpty) {
      return _foundUsers;
    } else {
      return _foundUsers
          .where((x) => x.customerName!.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }
  }

  void _loadAd() async {
    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {},
      ),
    ).load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
        adUnitId:_adUnitIdInterstitialAd,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              _loadInterstitialAd();
            }
          },
        )
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    final we = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
        SizedBox(
          height: he * 0.04,
        ),
        SizedBox(
          height: he * 0.03,
        ),
        FadeAnimationWidget(
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
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            height: 50.0,
            margin: const EdgeInsets.only(right: 13.0, left: 13.0, bottom: 26),
            child: CupertinoSearchTextField(
              placeholder: "Digite o nome do cliente...",
              style: const TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
              backgroundColor: Colors.white12,
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
              itemCount: getFilteredData().length,
              itemBuilder: (context, index) {
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
                      "${getFilteredData()[index].customerName}",
                      maxLines: 2,
                      style: const TextStyle(
                        color: whiteColor,
                        letterSpacing: 0.5,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text("Nº orçamento: ${getFilteredData()[index].id}",
                        style: const TextStyle(
                            color: whiteColor,
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
                            "Telefone: ${getFilteredData()[index].phone}",
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
                              "Data do orçamento: ${getFilteredData()[index].data}",
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
                          child: Text("Status: ${getFilteredData()[index].status}",
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
                          child: Text("Valor total: ${moneyConvert.convertFromDouble(getFilteredData()[index].totalValue!)}",
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
                          child: Text("Criado em: ${getFilteredData()[index].data}",
                              style: const TextStyle(
                                  color: whiteColor,
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
                                  visible: !getFilteredData()[index].checkBox!,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: SizedBox(
                                    width: 85.0,
                                    height: 52.0,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        whiteColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (!getFilteredData()[index].checkBox!) {
                                          getFilteredData()[index].checkBox = true;
                                          getFilteredData()[index].index = index;
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
                                          Text('Excluir', style: TextStyle(fontSize: 8.5, color: bgColor)),
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
                                      backgroundColor: whiteColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                    ),
                                    onPressed: () {
                                      budget.IDORCAMENTO =
                                          getFilteredData()[index].id;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BudgetTabView(
                                              item: getFilteredData()[index]),
                                        ),
                                      ).then((value) => setState(() {
                                            try {
                                              budget.IDORCAMENTO = '';
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
                                        Icon(Icons.open_in_new_rounded, color: bgColor,),
                                        SizedBox(height: 2.0),
                                        Text('Abrir', style: TextStyle(fontSize: 8.5, color: bgColor)),
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
                                      backgroundColor: whiteColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if(!UID.autoRenewing! && getFilteredData().length > 10) {
                                        await displayAlert.notificationError(context, "Erro!", "Você não possuí o plano premium onde é possível realizar orçamentos ilimitados").then((value) => {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => SubscriptionView()),
                                          ),
                                        });
                                      }
                                      else{
                                        budget.IDORCAMENTO =
                                            getFilteredData()[index].id;
                                        await _dialogDuplicate();
                                      }
                                    },
                                    child: const Column(
                                      children: <Widget>[
                                        SizedBox(height: 4),
                                        Icon(Icons.copy, color: bgColor,),
                                        SizedBox(height: 2.0),
                                        Text('Duplicar', style: TextStyle(fontSize: 8.5, color: bgColor)),
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
      ]),
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
              if(!UID.autoRenewing!) {
                await displayAlert.adsNotification(context).then((value) async => {
                  if(value == "Ver anuncio") {
                  _showInterstitialAd(),
                  novo.phone = '',
                  novo.customerName = '',
                  novo.companyName = '',
                  novo.address = '',
                  novo.email = '',
                  novo.generated = '',
                  novo.data = '',
                  novo.status = 'PENDENTE',
                  novo.zip = '',
                  novo.city = '',
                  novo.neighborhood = '',
                  novo.id = '',
                  novo.street = '',
                  budget.IDORCAMENTO = '',
                  Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BudgetTabView(item: novo)),
                 ).then((value) => setState(() async {
                    budget.IDORCAMENTO = '';
                  await getInformationOrcamento();
                    setState(() {
                      deleteItens.clear();
                      deleteVisible = false;
                      checkBoxAppear = false;
                    });
                  })),
                  }
                  else if(value == "Se tornar premium") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SubscriptionView()),
                    ),
                  }
                });
              }
              else{
                novo.phone = '';
                novo.customerName = '';
                novo.companyName = '';
                novo.address = '';
                novo.email = '';
                novo.generated = '';
                novo.data = '';
                novo.status = 'PENDENTE';
                novo.zip = '';
                novo.city = '';
                novo.neighborhood = '';
                novo.id = '';
                novo.street = '';
                budget.IDORCAMENTO = '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BudgetTabView(item: novo)),
                ).then((value) => setState(() async {
                  budget.IDORCAMENTO = '';
                  await getInformationOrcamento();
                  setState(() {
                    deleteItens.clear();
                    deleteVisible = false;
                    checkBoxAppear = false;
                  });
                }));
              }
            },
            backgroundColor: buttonColor,
            child: const Icon(
              Icons.add,
              color: Colors.black,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bannerAd != null
          ? SizedBox(width: we, height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!),
      ) : null,
    );
  }
}
