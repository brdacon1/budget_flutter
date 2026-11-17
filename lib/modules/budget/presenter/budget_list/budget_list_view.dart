import 'package:badges/badges.dart' as badges;
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/presenter/budget_list/budget_list_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/card/budget_list_card.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/modals/budget_list_actions_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/modals/budget_list_delete_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/modals/budget_list_duplicate_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/presenter/budget_tab/budget_tab_view.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/ads/banner_ad_widget.dart';

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
      backgroundColor: transparentColor,
      builder: (BuildContext dialogContext) {
        return BudgetListDuplicateBottomModalWidget(
          onConfirm: (clientData, quoteItems, comments, receipts) async {
            Navigator.of(dialogContext).pop();
            if (!mounted) return;
            final alertDisplayLoading = getIt<LoadingEventRepository>();
            try {
              await alertDisplayLoading.alertLoading(viewContext);
              await _viewModel.duplicateEvent(
                clientData,
                quoteItems,
                comments,
                receipts,
              );
              await _viewModel.getInformationOrcamento(refresh: true);
            } finally {
              if (mounted) {
                alertDisplayLoading.closeLoading(viewContext);
              }
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
      backgroundColor: transparentColor,
      builder: (BuildContext context) {
        return BudgetListDeleteBottomModalWidget(
          deleteItens: _viewModel.deleteItems,
          onRemove: (item) => _viewModel.removeDeleteItem(item),
          onConfirm: () async {
            await _viewModel.deleteData();
            _viewModel.clearDeleteItens();
            if (!mounted) return;
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
              badgeColor: badgeColor,
              borderRadius: BorderRadius.circular(40),
            ),
            badgeContent: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Center(
                child: Text(
                  _viewModel.deleteItems.length.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: whiteColor,
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
              shape: const StadiumBorder(),
              icon: const Icon(Icons.delete_outline_rounded, color: blackColor),
              label: Text(
                BudgetStrings.removeAll,
                style: const TextStyle(
                  color: blackColor,
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
              if (!(getIt<UserRepository>().selectUser.value?.autoRenewing ??
                  false)) {
                final value = await _viewModel.displayAlert.adsNotification(
                  context,
                );
                if (!mounted) return;
                if (value == "Ver anuncio") {
                  getIt<AdsRepository>().showInterstitial();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              BudgetTabView(item: _viewModel.customerInfoNew()),
                    ),
                  );
                  if (!mounted) return;
                  getIt<BudgetRepository>().clearSelectBudget();
                  await _viewModel.getInformationOrcamento(refresh: true);
                  _viewModel.clearDeleteItens();
                } else if (value == "Se tornar premium") {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SubscriptionView()),
                  );
                }
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
            shape: const StadiumBorder(),
            icon: const Icon(Icons.add, color: blackColor, size: 20),
            label: Text(
              BudgetStrings.newBudget,
              style: const TextStyle(
                color: blackColor,
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

  void _openBudget(CustomerInfo item) {
    getIt<BudgetRepository>().selectBudget.value = item;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BudgetTabView(item: item)),
    ).then((_) {
      getIt<BudgetRepository>().clearSelectBudget();
      _viewModel.clearDeleteItens();
    });
  }

  Future<void> _duplicateBudget(CustomerInfo item) async {
    if (!(getIt<UserRepository>().selectUser.value?.autoRenewing ?? false) &&
        _viewModel.totalBudgetCount > 10) {
      await _viewModel.displayAlert.notificationError(
        context,
        "Erro!",
        "Você não possuí o plano premium onde é possível realizar orçamentos ilimitados",
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SubscriptionView()),
      );
    } else {
      getIt<BudgetRepository>().selectBudget.value = item;
      await _dialogDuplicate();
    }
  }

  Future<void> _openActions(CustomerInfo item, int index) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: transparentColor,
      builder:
          (_) => BudgetListActionsBottomModalWidget(
            item: item,
            moneyConvert: moneyConvert,
            onOpen: () => _openBudget(item),
            onDuplicate: () => _duplicateBudget(item),
            onDelete: () {
              if (!(item.checkBox ?? false)) _viewModel.toggleDeleteItem(index);
            },
          ),
    );
  }

  Widget _buildListView() {
    final data = _viewModel.getFilteredData();
    final isEmpty =
        data.isEmpty && !_viewModel.isRefreshing && !_viewModel.isLoadingMore;

    if (isEmpty) {
      return Expanded(
        child: RefreshIndicator(
          color: refreshIndicatorColor,
          backgroundColor: bgColor,
          onRefresh: () async {
            await _viewModel.getInformationOrcamento(refresh: true);
            _viewModel.clearDeleteItens();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.folder_open_outlined,
                      color: emptyStateIconColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      BudgetStrings.emptyStateTitle,
                      style: GoogleFonts.heebo(
                        color: loadingIndicatorColor,
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
        color: refreshIndicatorColor,
        backgroundColor: bgColor,
        onRefresh: () async {
          await _viewModel.getInformationOrcamento(refresh: true);
          _viewModel.clearDeleteItens();
        },
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          itemCount: data.length + (_viewModel.isLoadingMore ? 1 : 0),
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
                      color: loadingIndicatorColor,
                    ),
                  ),
                ),
              );
            }
            final item = data[index];
            return BudgetListCard(
              item: item,
              moneyConvert: moneyConvert,
              onTap: () => _openBudget(item),
              onMore: () => _openActions(item, index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: CupertinoSearchTextField(
        placeholder: BudgetStrings.searchPlaceholder,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        style: GoogleFonts.heebo(color: whiteColor, fontSize: 16),
        placeholderStyle: GoogleFonts.heebo(
          color: mutedTextColor,
          fontSize: 16,
        ),
        backgroundColor: secondaryColor,
        borderRadius: BorderRadius.circular(14),
        itemColor: mutedTextColor,
        controller: searchController,
        onChanged: _viewModel.onSearchTextChanged,
      ),
    );
  }

  Widget _buildHeaderScreen() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            BudgetStrings.screenTitle,
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    return Column(
      children: <Widget>[
        _buildHeaderScreen(),
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
          return _buildScreen();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFloatingButton(height: he),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
