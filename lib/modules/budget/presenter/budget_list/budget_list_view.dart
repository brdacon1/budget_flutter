import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/presenter/budget_draft_notifier.dart';
import 'package:oflite/modules/budget/presenter/budget_list/budget_list_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/budget_list_empty_detail.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/budget_list_status_filter.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/card/budget_list_card.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/modals/budget_list_actions_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/modals/budget_list_duplicate_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/new_budget_gate.dart';
import 'package:oflite/modules/budget/presenter/budget_tab/budget_tab_view.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/map_launcher/domain/usecase/resolve_address_maps_usecase.dart';
import 'package:oflite/modules/core/map_launcher/presenter/components/map_chooser_action_sheet.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_master_detail.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/responsive_widget.dart';

class BudgetListView extends StatefulWidget {
  /// Com cliente: mostra só os orçamentos dele (mesmo telefone), sem busca,
  /// e "Novo orçamento" já vem com os dados do cliente.
  final CustomerInfo? customer;

  const BudgetListView({super.key, this.customer});

  @override
  State<BudgetListView> createState() => _BudgetListView();
}

class _BudgetListView extends State<BudgetListView> {
  final BudgetListViewModel _viewModel = getIt<BudgetListViewModel>();
  ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();
  final ScrollController _scrollController = ScrollController();

  /// Navigator do painel de detalhe (tela larga).
  final GlobalKey<NavigatorState> _detailKey = GlobalKey<NavigatorState>();

  /// Rascunho do orçamento novo e orçamento aberto (selecionado): a lista
  /// destaca o aberto e mostra o rascunho como um card que se atualiza ao vivo.
  final BudgetDraftNotifier _draft = getIt<BudgetDraftNotifier>();
  final _selected = getIt<BudgetRepository>().selectBudget;

  /// Lista + detalhe lado a lado: só em tela larga e na lista principal (a
  /// lista "orçamentos do cliente" continua empilhando telas).
  bool get _splitView =>
      widget.customer == null && ResponsiveWidget.isDesktop(context);

  @override
  void initState() {
    _viewModel.customer = widget.customer;
    if (widget.customer == null) getIt<BudgetRepository>().clearSelectBudget();
    getIt<AdsRepository>().loadInterstitial();
    _scrollController.addListener(_onScroll);
    _draft.addListener(_onOpenBudgetChanged);
    _selected.addListener(_onOpenBudgetChanged);
    _viewModel.initialScreen();
    super.initState();
  }

  /// Tela larga: ao entrar em Orçamentos já abre o mais recente (primeiro da
  /// lista, ordenada por id decrescente). Só uma vez por entrada na aba — se o
  /// usuário fechar o detalhe, não reabre.
  bool _autoOpened = false;

  void _openMostRecentOnce(List<CustomerInfo> data) {
    if (_autoOpened || !mounted || !_splitView || data.isEmpty) return;
    if (_draft.value != null || _detailKey.currentState == null) return;
    _autoOpened = true;
    _openBudget(data.first);
  }

  /// Paginação por rolagem: se a página carregada cabe inteira na área visível
  /// (tela larga/alta), a lista não rola e o `_onScroll` nunca dispara. Então,
  /// enquanto não houver o que rolar e ainda houver páginas, pede a próxima.
  void _loadMoreIfNotScrollable() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent > 0) return;
    _viewModel.loadMore();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      _viewModel.loadMore();
    }
  }

  /// Fora do build (o formulário muda esses valores em initState): reconstrói
  /// a lista depois do frame.
  void _onOpenBudgetChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  /// Orçamento aberto no painel (tela larga): destaque da lista.
  bool _isOpen(CustomerInfo item) {
    final id = item.id ?? '';
    return _splitView && id.isNotEmpty && id == _selected.value?.id;
  }

  @override
  void dispose() {
    _draft.removeListener(_onOpenBudgetChanged);
    _selected.removeListener(_onOpenBudgetChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _viewModel.dispose();
    // Volta o orçamento de origem como selecionado (PDF etc. dependem dele).
    if (widget.customer != null) {
      getIt<BudgetRepository>().selectBudget.value = widget.customer;
    }
    super.dispose();
  }

  Future<void> _dialogDuplicate() async {
    final viewContext = context;
    await showAppModal<void>(
      context,
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

    final openId = _selected.value?.id;
    final deletesActive =
        openId != null && _viewModel.selectedIds.contains(openId);
    final ok = await _viewModel.deleteSelected();
    if (!mounted) return;
    if (ok && deletesActive) {
      _detailKey.currentState?.popUntil((route) => route.isFirst);
    }
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
        if (!await confirmNewBudgetAccess(context) || !mounted) return;
        if (widget.customer != null) return _createForCustomer();
        if (_splitView) {
          return _showDetail(BudgetTabView(item: _viewModel.customerInfoNew()));
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => BudgetTabView(item: _viewModel.customerInfoNew()),
          ),
        );
        if (!mounted) return;
        getIt<BudgetRepository>().clearSelectBudget();
        await _viewModel.getInformationOrcamento(refresh: true);
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
    final data = _viewModel.getFilteredData().where(
      (b) => !_viewModel.isOrigin(b),
    );
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

  Future<void> _createForCustomer() async {
    final loading = getIt<LoadingEventRepository>();
    await loading.alertLoading(context);
    final created = await _viewModel.createForCustomer();
    if (!mounted) return;
    loading.closeLoading(context);
    if (created == null) {
      await _viewModel.displayAlert.notificationError(
        context,
        BudgetStrings.createErrorTitle,
        BudgetStrings.createErrorMessage,
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BudgetTabView(
              item: created,
              initialIndex: 1,
              fromCustomerBudgets: true,
            ),
      ),
    );
    getIt<BudgetRepository>().clearSelectBudget();
  }

  void _openBudget(CustomerInfo item) {
    getIt<BudgetRepository>().selectBudget.value = item;
    if (_splitView) {
      _showDetail(BudgetTabView(item: item));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BudgetTabView(
              item: item,
              fromCustomerBudgets: widget.customer != null,
            ),
      ),
    ).then((_) {
      getIt<BudgetRepository>().clearSelectBudget();
    });
  }

  /// Abre [page] no painel de detalhe, substituindo o que estiver aberto.
  void _showDetail(Widget page) {
    _detailKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => page),
      (route) => route.isFirst,
    );
  }

  /// Detalhe fechado (voltar na tela do orçamento): limpa a seleção e
  /// atualiza a lista (novo orçamento, totais alterados).
  void _onDetailClosed() {
    if (!mounted) return;
    getIt<BudgetRepository>().clearSelectBudget();
    _viewModel.getInformationOrcamento(refresh: true);
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
        MaterialPageRoute(builder: (context) => const SubscriptionView()),
      );
    } else {
      getIt<BudgetRepository>().selectBudget.value = item;
      await _dialogDuplicate();
    }
  }

  Future<void> _showMapError() => _viewModel.displayAlert.notificationError(
    context,
    BudgetStrings.mapErrorTitle,
    BudgetStrings.mapErrorMessage,
  );

  /// Android: seletor nativo do sistema. iOS: action sheet nativa.
  Future<void> _openMap(CustomerInfo item) async {
    final result = await _viewModel.resolveMaps(item);
    if (!mounted) return;
    switch (result) {
      case AddressMapsOpenedBySystem():
        return;
      case AddressMapsUnavailable():
        return _showMapError();
      case AddressMapsAvailable(:final maps):
        return showMapChooserSheet(
          context,
          maps: maps,
          title: BudgetStrings.chooseMap,
          cancelLabel: BudgetStrings.cancel,
        );
    }
  }

  Future<void> _openActions(CustomerInfo item) {
    return showAppModal<void>(
      context,
      isScrollControlled: false,
      builder:
          (_) => BudgetListActionsBottomModalWidget(
            item: item,
            moneyConvert: moneyConvert,
            onMap: () => _openMap(item),
            onDuplicate: () => _duplicateBudget(item),
            onDelete: () {
              if (!_viewModel.isSelected(item)) _viewModel.toggleSelect(item);
            },
          ),
    );
  }

  Widget _buildListView() {
    final data = _viewModel.getFilteredData();
    // Orçamento novo em edição (tela larga): card de rascunho no topo.
    final draft = _splitView ? _draft.value : null;
    final offset = draft == null ? 0 : 1;
    final isEmpty =
        data.isEmpty &&
        draft == null &&
        !_viewModel.isRefreshing &&
        !_viewModel.isLoadingMore;

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
                      widget.customer == null
                          ? BudgetStrings.emptyStateTitle
                          : _viewModel.customerHasPhone
                          ? BudgetStrings.customerBudgetsEmpty
                          : BudgetStrings.customerBudgetsNoPhone,
                      textAlign: TextAlign.center,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoreIfNotScrollable();
      _openMostRecentOnce(data);
    });

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
          itemCount: offset + data.length + (_viewModel.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (draft != null && index == 0) {
              return BudgetListCard(
                item: draft,
                draft: true,
                active: true,
                selected: false,
                moneyConvert: moneyConvert,
                onTap: null,
                onMore: null,
              );
            }
            if (index - offset >= data.length) {
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
            final item = data[index - offset];
            return BudgetListCard(
              item: item,
              selected: _viewModel.isSelected(item),
              active: _isOpen(item),
              moneyConvert: moneyConvert,
              // Orçamento de origem: já está aberto por baixo, sem ações.
              onTap:
                  _viewModel.isOrigin(item)
                      ? null
                      : () =>
                          _viewModel.selectionMode
                              ? _viewModel.toggleSelect(item)
                              : _openBudget(item),
              onMore:
                  _viewModel.isOrigin(item)
                      ? null
                      : () =>
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
        if (widget.customer == null) ...[
          _buildHeaderScreen(),
          _buildSearchBar(),
        ] else ...[
          AppHeaderSecondTitle(
            titlePage: BudgetStrings.customerBudgetsTitle,
            secondTitle: widget.customer!.customerName ?? '',
            onBack: () => Navigator.pop(context),
            isBottomPadding: false,
          ),
          const SizedBox(height: 12),
        ],
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
    final list = Scaffold(
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
    if (!_splitView) return list;
    return AppMasterDetail(
      master: list,
      emptyDetail: const BudgetListEmptyDetail(),
      detailNavigatorKey: _detailKey,
      hideBackOnRootScreens: true,
      onDetailClosed: _onDetailClosed,
    );
  }
}
