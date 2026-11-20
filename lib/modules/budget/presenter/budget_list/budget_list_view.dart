import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/presenter/budget_list/budget_list_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/budget_list_status_filter.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/card/budget_list_card.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/modals/budget_list_actions_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/modals/budget_list_duplicate_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/presenter/budget_tab/budget_tab_view.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';

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

  Future<void> _confirmDelete() async {
    final count = _viewModel.selectedIds.length;
    final confirm = await showConfirmBottomModal(
      context,
      title: BudgetStrings.removeTitle(count),
      message: BudgetStrings.removeMessage,
    );
    if (!confirm || !mounted) return;

    final ok = await _viewModel.deleteSelected();
    if (!mounted) return;
    if (ok) {
      await _viewModel.displayAlert.notificationNotCloseScreen(
        context,
        BudgetStrings.removeSuccessTitle,
        BudgetStrings.removeSuccessMessage,
      );
    } else {
      await _viewModel.displayAlert.notificationError(
        context,
        BudgetStrings.removeErrorTitle,
        BudgetStrings.removeErrorMessage,
      );
    }
  }

  Widget _buildDeleteFloatingButton() {
    return FloatingActionButton.extended(
      heroTag: 'delete',
      onPressed: _viewModel.deleting ? null : _confirmDelete,
      backgroundColor: statusRejectedColor,
      shape: const StadiumBorder(),
      icon:
          _viewModel.deleting
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: whiteColor,
                ),
              )
              : const Icon(Icons.delete_outline_rounded, color: whiteColor),
      label: Text(
        BudgetStrings.removeCount(_viewModel.selectedIds.length),
        style: const TextStyle(
          color: whiteColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildAddItemsFloatingButton() {
    return FloatingActionButton.extended(
      heroTag: "adicionar",
      onPressed: () async {
        if (!(getIt<UserRepository>().selectUser.value?.autoRenewing ??
            false)) {
          final value = await _viewModel.displayAlert.adsNotification(context);
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
    );
  }

  Widget _buildFloatingButton() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder:
          (context, _) =>
              _viewModel.selectionMode
                  ? _buildDeleteFloatingButton()
                  : _buildAddItemsFloatingButton(),
    );
  }

  Widget _buildSelectionBar() {
    final count = _viewModel.selectedIds.length;
    final data = _viewModel.getFilteredData();
    final allSelected = data.isNotEmpty && data.every(_viewModel.isSelected);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 20, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: BudgetStrings.cancelSelection,
            onPressed: _viewModel.clearSelection,
            icon: const Icon(Icons.close, color: whiteColor),
          ),
          Text(
            BudgetStrings.selectedCount(count),
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _viewModel.selectAllFiltered,
            style: TextButton.styleFrom(foregroundColor: buttonColor),
            child: Text(
              allSelected ? BudgetStrings.clearAll : BudgetStrings.selectAll,
            ),
          ),
        ],
      ),
    );
  }

  void _openBudget(CustomerInfo item) {
    getIt<BudgetRepository>().selectBudget.value = item;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BudgetTabView(item: item)),
    ).then((_) {
      getIt<BudgetRepository>().clearSelectBudget();
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

  Future<void> _openActions(CustomerInfo item) {
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
              if (!_viewModel.isSelected(item)) _viewModel.toggleSelect(item);
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
              selected: _viewModel.isSelected(item),
              moneyConvert: moneyConvert,
              onTap:
                  () =>
                      _viewModel.selectionMode
                          ? _viewModel.toggleSelect(item)
                          : _openBudget(item),
              onMore:
                  () =>
                      _viewModel.selectionMode
                          ? _viewModel.toggleSelect(item)
                          : _openActions(item),
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
        if (_viewModel.canFilterStatus)
          BudgetListStatusFilter(
            status: _viewModel.status,
            onStatus: _viewModel.selectStatus,
          ),
        if (_viewModel.isSearching)
          const LinearProgressIndicator(
            minHeight: 2,
            color: loadingIndicatorColor,
            backgroundColor: transparentColor,
          ),
        if (_viewModel.selectionMode) _buildSelectionBar(),
        _buildListView(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return _buildScreen();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFloatingButton(),
    );
  }
}
