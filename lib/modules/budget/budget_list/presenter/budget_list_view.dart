import 'package:badges/badges.dart' as badges;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/budget_tab/presenter/budget_tab_view.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/ads/banner_ad_widget.dart';

import 'budget_list_view_model.dart';
import 'components/card/budget_list_card.dart';
import 'components/modals/budget_list_delete_bottom_modal_widget.dart';
import 'components/modals/budget_list_duplicate_bottom_modal_widget.dart';

class BudgetListView extends StatefulWidget {
  const BudgetListView({super.key});

  @override
  State<BudgetListView> createState() => _BudgetListView();
}

class _BudgetListView extends State<BudgetListView> {
  final BudgetListViewModel _viewModel = getIt<BudgetListViewModel>();
  ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    getIt<BudgetRepository>().clearSelectBudget();
    getIt<AdsRepository>().loadInterstitial();
    _scrollController.addListener(_onScroll);
    _viewModel.initialScreen();
    super.initState();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      _viewModel.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
            final alertDisplayLoading = getIt<LoadingEventRepository>();
            try {
              await alertDisplayLoading.alertLoading(viewContext);
              await _viewModel.duplicateEvent(clientData, quoteItems, comments);
              await _viewModel.getInformationOrcamento(refresh: true);
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
          deleteItens: _viewModel.deleteItems,
          onRemove: (item) => _viewModel.removeDeleteItem(item),
          onConfirm: () async {
            await _viewModel.deleteData();
            _viewModel.clearDeleteItens();
            await _viewModel.displayAlert.notification(
              context,
              "Tudo Certo!",
              "Orçamentos removidos com sucesso!",
            );
          },
        );
      },
    ).then((value) {
      setState(() {});
    });
  }

  Widget _buildDeleteFloatingButton() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Visibility(
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
                  _viewModel.deleteItems.length.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            child: FloatingActionButton.extended(
              heroTag: "delete",
              onPressed: _dialogDeleteBuilder,
              backgroundColor: buttonColor,
              elevation: 4,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.black,
              ),
              label: const Text(
                'Remover todos',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddItemsFloatingButton() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Visibility(
          visible: !_viewModel.deleteVisible,
          child: FloatingActionButton.extended(
            heroTag: "adicionar",
            onPressed: () async {
              if (!(getIt<UserRepository>().selectUser.value?.AutoRenewing ??
                  false)) {
                await _viewModel.displayAlert
                    .adsNotification(context)
                    .then(
                      (value) async => {
                        if (value == "Ver anuncio")
                          {
                            getIt<AdsRepository>().showInterstitial(),
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BudgetTabView(
                                      item: _viewModel.customerInfoNew(),
                                    ),
                              ),
                            ).then((_) async {
                              getIt<BudgetRepository>().clearSelectBudget();
                              await _viewModel.getInformationOrcamento(
                                refresh: true,
                              );
                              _viewModel.clearDeleteItens();
                            }),
                          }
                        else if (value == "Se tornar premium")
                          {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubscriptionView(),
                              ),
                            ),
                          },
                      },
                    );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            BudgetTabView(item: _viewModel.customerInfoNew()),
                  ),
                ).then((_) async {
                  getIt<BudgetRepository>().clearSelectBudget();
                  await _viewModel.getInformationOrcamento(refresh: true);
                  _viewModel.clearDeleteItens();
                });
              }
            },
            backgroundColor: buttonColor,
            elevation: 4,
            icon: const Icon(Icons.add, color: Colors.black, size: 20),
            label: const Text(
              'Novo orçamento',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingButton({required double height}) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            _buildDeleteFloatingButton(),
            _buildAddItemsFloatingButton(),
          ],
        );
      },
    );
  }

  Widget _buildListView() {
    final data = _viewModel.getFilteredData();
    final isEmpty = data.isEmpty &&
        !_viewModel.isRefreshing &&
        !_viewModel.isLoadingMore;

    if (isEmpty) {
      return Expanded(
        child: RefreshIndicator(
          color: Colors.cyan[50],
          backgroundColor: bgColor,
          onRefresh: () async {
            await _viewModel.getInformationOrcamento(refresh: true);
            _viewModel.clearDeleteItens();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.folder_open_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      BudgetStrings.emptyStateTitle,
                      style: GoogleFonts.heebo(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        color: Colors.cyan[50],
        backgroundColor: bgColor,
        onRefresh: () async {
          await _viewModel.getInformationOrcamento(refresh: true);
          _viewModel.clearDeleteItens();
        },
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          padding: const EdgeInsets.only(
            bottom: 170,
            left: 15,
            right: 15,
            top: 0,
          ),
          itemCount:
              data.length +
              (_viewModel.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= data.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                ),
              );
            }
            final item = data[index];
            return BudgetListCard(
              item: item,
              moneyConvert: moneyConvert,
              onDelete: () {
                if (!item.checkBox!) {
                  _viewModel.toggleDeleteItem(index);
                }
              },
              onOpen: () {
                getIt<BudgetRepository>().selectBudget.value = item;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BudgetTabView(item: item),
                  ),
                ).then((_) async {
                  getIt<BudgetRepository>().clearSelectBudget();
                  await _viewModel.getInformationOrcamento(refresh: true);
                  _viewModel.clearDeleteItens();
                });
              },
              onDuplicate: () async {
                if (!(getIt<UserRepository>().selectUser.value?.AutoRenewing ??
                        false) &&
                    _viewModel.totalBudgetCount > 10) {
                  await _viewModel.displayAlert
                      .notificationError(
                        context,
                        "Erro!",
                        "Você não possuí o plano premium onde é possível realizar orçamentos ilimitados",
                      )
                      .then(
                        (value) => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubscriptionView(),
                            ),
                          ),
                        },
                      );
                } else {
                  getIt<BudgetRepository>().selectBudget.value = item;
                  await _dialogDuplicate();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
        controller: searchController,
        onChanged: _viewModel.onSearchTextChanged,
      ),
    );
  }

  Widget _buildHeaderScreen({required double height}) {
    return Column(
      children: [
        SizedBox(height: height * 0.04),
        SizedBox(height: height * 0.03),
        Container(
          margin: const EdgeInsets.only(right: 125.0),
          child: Text(
            "Meus orçamentos",
            style: GoogleFonts.heebo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreen({required double height}) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _buildHeaderScreen(height: height),
        SizedBox(height: height * 0.03),
        _buildSearchBar(),
        _buildListView(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return _buildScreen(height: he);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFloatingButton(height: he),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
