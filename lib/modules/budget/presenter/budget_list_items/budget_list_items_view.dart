import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_master_detail.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_adaptive_grid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/presenter/budget_item_quantity/budget_item_quantity_view.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/product_price_creator/product_price_creator_view.dart';
import 'package:oflite/modules/product/presenter/product_price_picker/product_price_picker_view.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';

import 'budget_list_items_view_model.dart';
import 'components/budget_list_items_card.dart';
import 'components/budget_list_items_total_bar.dart';

class BudgetListItemsView extends StatefulWidget {
  final CustomerInfo item;

  const BudgetListItemsView({super.key, required this.item});

  @override
  State<BudgetListItemsView> createState() => _BudgetListItemsView();
}

class _BudgetListItemsView extends State<BudgetListItemsView> {
  late final BudgetListItemsViewModel _viewModel;
  final _displayAlert = getIt<DisplayAlertRepository>();

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetListItemsViewModel(item: widget.item);
    getIt<BudgetRepository>().selectBudget.value = widget.item;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.getListItens();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final count = _viewModel.selected.length;
    final confirm = await showConfirmBottomModal(
      context,
      title: count == 1 ? 'Remover item' : 'Remover $count itens',
      message: 'Essa ação não pode ser desfeita.',
    );
    if (!confirm || !mounted) return;

    final ok = await _viewModel.deleteSelected();
    if (!mounted) return;
    if (ok) {
      await _displayAlert.notificationNotCloseScreen(
        context,
        count == 1 ? 'Item removido' : 'Itens removidos',
        'O total do orçamento foi atualizado.',
      );
    } else {
      await _displayAlert.notificationError(
        context,
        'Não foi possível remover',
        'Verifique sua conexão e tente novamente.',
      );
    }
  }

  Future<void> _openItem(ItemsBudget item) async {
    final saved = await showBudgetItemQuantityBottomModal(
      context,
      budgetId: widget.item.id!,
      item: item,
    );
    if (!saved || !mounted) return;
    await _viewModel.getListItens();
    if (!mounted) return;
    await _displayAlert.notificationNotCloseScreen(
      context,
      BudgetStrings.itemQuantitySuccessTitle,
      BudgetStrings.itemQuantitySuccessMessage,
    );
  }

  Future<void> _addItem() async {
    if (await _viewModel.getProductCount() > 0) {
      if (!mounted) return;
      final value = await _displayAlert.listNotification(context);
      if (value == "Criar novo item") {
        await _showProductPriceCreatorBottomModal();
      } else if (value == "Selecionar da lista de preço") {
        await _openPriceList();
      }
    } else {
      await _showProductPriceCreatorBottomModal();
    }
  }

  Future<void> _showProductPriceCreatorBottomModal() async {
    await showProductPriceCreatorBottomModal(
      context,
      item: ProductPriceModel.fromItemsBudget(_viewModel.newItemsBudget),
      fromListItem: true,
    );
    await _viewModel.getListItens();
  }

  Future<void> _openPriceList() async {
    final added = await showProductPricePickerBottomModal(
      context,
      budgetId: widget.item.id!,
    );
    if (!added || !mounted) return;
    await _viewModel.getListItens();
    if (!mounted) return;
    await _displayAlert.notificationNotCloseScreen(
      context,
      ProductPtString.doneTitle,
      ProductPtString.cartAddSuccess,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        controller: _viewModel.searchController,
        onChanged: _viewModel.onSearchTextChanged,
        cursorColor: buttonColor,
        style: GoogleFonts.heebo(color: whiteColor, fontSize: 15),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: secondaryColor,
          hintText: 'Buscar item',
          hintStyle: GoogleFonts.heebo(color: slateGray, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: mutedTextColor),
          suffixIcon:
              _viewModel.searchController.text.isEmpty
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.close, color: mutedTextColor),
                    onPressed: () {
                      _viewModel.searchController.clear();
                      _viewModel.onSearchTextChanged('');
                    },
                  ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    final count = _viewModel.selected.length;
    final allSelected =
        _viewModel.filteredItems.isNotEmpty &&
        _viewModel.filteredItems.every(_viewModel.selected.contains);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 20, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancelar seleção',
            onPressed: _viewModel.clearSelection,
            icon: const Icon(Icons.close, color: whiteColor),
          ),
          Text(
            count == 1 ? '1 selecionado' : '$count selecionados',
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
            child: Text(allSelected ? 'Limpar' : 'Selecionar todos'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final searching = _viewModel.searchController.text.isNotEmpty;
    return ListView(
      children: [
        const SizedBox(height: 60),
        Icon(
          searching ? Icons.search_off : Icons.playlist_add,
          color: mutedTextColor,
          size: 56,
        ),
        const SizedBox(height: 12),
        Text(
          searching ? 'Nenhum item encontrado' : 'Adicione o primeiro item',
          textAlign: TextAlign.center,
          style: GoogleFonts.heebo(
            color: whiteColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          searching
              ? 'Tente outra descrição.'
              : 'Produtos e serviços aparecem aqui com o total do orçamento.',
          textAlign: TextAlign.center,
          style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator(color: buttonColor));
    }
    final items = _viewModel.filteredItems;
    return RefreshIndicator(
      color: refreshIndicatorColor,
      backgroundColor: bgColor,
      onRefresh: _viewModel.getListItens,
      child:
          items.isEmpty
              ? _buildEmpty()
              : AppAdaptiveGrid(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final it = items[index];
                  return BudgetListItemsCard(
                    item: it,
                    selected: _viewModel.isSelected(it),
                    moneyConvert: _viewModel.moneyConvert,
                    onTap: () => _openItem(it),
                    onToggleSelect: () => _viewModel.toggleSelect(it),
                  );
                },
              ),
    );
  }

  Widget _buildFab() {
    if (_viewModel.selectionMode) {
      return FloatingActionButton.extended(
        heroTag: 'delete',
        onPressed: _viewModel.deleting ? null : _confirmDelete,
        backgroundColor: statusRejectedColor,
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
          'Remover (${_viewModel.selected.length})',
          style: GoogleFonts.heebo(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    return FloatingActionButton.extended(
      heroTag: 'adicionar',
      onPressed: _addItem,
      backgroundColor: buttonColor,
      icon: const Icon(Icons.add, color: blackColor),
      label: Text(
        'Adicionar item',
        style: GoogleFonts.heebo(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final money = _viewModel.moneyConvert;
        final count = _viewModel.budgets.length;
        return Scaffold(
          backgroundColor: bgColor,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: <Widget>[
                AppHeaderSecondTitle(
                  showBack: !AppDetailPane.hidesBackOf(context),
                  titlePage: 'Itens do orçamento',
                  secondTitle: count == 1 ? '1 item' : '$count itens',
                  onBack: () => Navigator.pop(context, true),
                ),
                _buildSearchBar(),
                if (_viewModel.selectionMode) _buildSelectionBar(),
                Expanded(child: _buildList()),
              ],
            ),
          ),
          floatingActionButton: _buildFab(),
          bottomNavigationBar: BudgetListItemsTotalBar(
            total: money.convertFromDouble(_viewModel.totalBudget),
            products: money.convertFromDouble(_viewModel.totalProducts),
            services: money.convertFromDouble(_viewModel.totalServices),
          ),
        );
      },
    );
  }
}
