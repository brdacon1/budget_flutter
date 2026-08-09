import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/common/widgets/ads/banner_ad_widget.dart';
import 'package:oflite/common/widgets/ads/interstitial_ad_service.dart';
import 'package:oflite/models/global_uid_budget.dart' as budget;
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:oflite/presentations/budget/budget_tab/budget_tab_view.dart';
import 'package:oflite/presentations/subscription/subscription_view.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/services/loading_event.dart';
import 'package:badges/badges.dart' as badges;
import 'components/budget_list_card.dart';
import 'components/modals/budget_list_delete_bottom_modal_widget.dart';
import 'components/modals/budget_list_duplicate_bottom_modal_widget.dart';
import 'budget_list_view_model.dart';

class BudgetListView extends StatefulWidget {
  const BudgetListView({Key? key}) : super(key: key);

  @override
  State<BudgetListView> createState() => _BudgetListView();
}

class _BudgetListView extends State<BudgetListView> {
  final BudgetListViewModel _viewModel = BudgetListViewModel();
  ConvertCoin moneyConvert = ConvertCoin();

  @override
  void initState() {
    budget.IDORCAMENTO = '';
    // Pré-carrega o intersticial em background, sem travar a tela.
    InterstitialAdService.instance.load();
    _viewModel.initialScreen();
    super.initState();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _dialogDuplicate() async {
    final viewContext = context;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return BudgetListDuplicateBottomModalWidget(
          onConfirm: (clientData, quoteItems, comments) async {
            Navigator.of(dialogContext).pop();
            var alertDisplayLoading = LoadingEvent();
            try {
              await alertDisplayLoading.alertLoading(viewContext);
              await _viewModel.duplicateEvent(clientData, quoteItems, comments);
              await _viewModel.getInformationOrcamento();
            } finally {
              alertDisplayLoading.closeLoading(viewContext);
            }
          },
        );
      },
    );
  }

  Future<void> _dialogDeleteBuilder() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BudgetListDeleteBottomModalWidget(
          deleteItens: _viewModel.deleteItens,
          onRemove: (item) => _viewModel.removeDeleteItem(item),
          onConfirm: () async {
            await _viewModel.deleteData();
            _viewModel.clearDeleteItens();
            await _viewModel.displayAlert.notification(
                context, "Tudo Certo!", "Orçamentos removidos com sucesso!");
          },
        );
      },
    ).then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
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
                margin:
                    const EdgeInsets.only(right: 13.0, left: 13.0, bottom: 26),
                child: CupertinoSearchTextField(
                  placeholder: "Digite o nome do cliente...",
                  style: const TextStyle(
                    color: whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                  backgroundColor: Colors.white12,
                  itemColor: whiteColor,
                  controller: searchController,
                  onChanged: _viewModel.onSearchTextChanged,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Colors.cyan[50],
                backgroundColor: bgColor,
                onRefresh: () async {
                  await _viewModel.getInformationOrcamento();
                  _viewModel.clearDeleteItens();
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.only(bottom: 170, left: 15, right: 15, top: 0),
                  itemCount: _viewModel.getFilteredData().length,
                  itemBuilder: (context, index) {
                    final item = _viewModel.getFilteredData()[index];
                    return BudgetListCard(
                      item: item,
                      moneyConvert: moneyConvert,
                      onDelete: () {
                        if (!item.checkBox!) {
                          _viewModel.toggleDeleteItem(index);
                        }
                      },
                      onOpen: () {
                        budget.IDORCAMENTO = item.id;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BudgetTabView(item: item),
                          ),
                        ).then((_) async {
                          budget.IDORCAMENTO = '';
                          await _viewModel.getInformationOrcamento();
                          _viewModel.clearDeleteItens();
                        });
                      },
                      onDuplicate: () async {
                        if (!UID.autoRenewing! &&
                            _viewModel.getFilteredData().length > 10) {
                          await _viewModel.displayAlert
                              .notificationError(context, "Erro!",
                                  "Você não possuí o plano premium onde é possível realizar orçamentos ilimitados")
                              .then((value) => {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              SubscriptionView()),
                                    ),
                                  });
                        } else {
                          budget.IDORCAMENTO = item.id;
                          await _dialogDuplicate();
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ]);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Visibility(
                visible: _viewModel.deleteVisible,
                child: badges.Badge(
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: const Color.fromARGB(255, 231, 15, 87),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  badgeContent: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Center(
                      child: Text(
                        _viewModel.deleteItens.length.toString(),
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
                  if (!UID.autoRenewing!) {
                    await _viewModel.displayAlert.adsNotification(context).then(
                        (value) async => {
                              if (value == "Ver anuncio")
                                {
                                  InterstitialAdService.instance.show(),
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => BudgetTabView(
                                            item: _viewModel.novoOrcamento())),
                                  ).then((_) async {
                                    budget.IDORCAMENTO = '';
                                    await _viewModel.getInformationOrcamento();
                                    _viewModel.clearDeleteItens();
                                  }),
                                }
                              else if (value == "Se tornar premium")
                                {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            SubscriptionView()),
                                  ),
                                }
                            });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              BudgetTabView(item: _viewModel.novoOrcamento())),
                    ).then((_) async {
                      budget.IDORCAMENTO = '';
                      await _viewModel.getInformationOrcamento();
                      _viewModel.clearDeleteItens();
                    });
                  }
                },
                backgroundColor: buttonColor,
                child: const Icon(
                  Icons.add,
                  color: Colors.black,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
