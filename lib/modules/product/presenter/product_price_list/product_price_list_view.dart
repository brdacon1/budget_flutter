import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_adaptive_grid.dart';
import 'package:oflite/modules/budget/presenter/budget_list_items/components/budget_list_items_category_filter.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/product_price_list/components/product_price_card.dart';
import 'package:oflite/modules/product/presenter/product_price_list/components/product_price_list_header.dart';
import 'package:oflite/modules/product/presenter/product_price_list/components/product_price_selection_bar.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';
import 'package:oflite/shared/common/constants/colors.dart';

import 'product_price_list_view_model.dart';

/// Tela de **lista de preço** (produtos/serviços).
///
/// `StatefulWidget` que cria o [ProductPriceListViewModel] em `initState` e o
/// descarta em `dispose`. Toda a reconstrução reativa acontece via
/// `AnimatedBuilder(animation: _viewModel, ...)` — **nenhum `setState`**.
///
/// A View apenas compõe a estrutura (header + barra de seleção + lista +
/// FABs) e delega as ações ao ViewModel. Remoção: o check circular do card
/// marca o item → "Remover (n)" → confirmação (mesmo fluxo da lista de itens
/// do orçamento). Os blocos visuais repetidos vivem em `components/`
/// ([ProductPriceListHeader], [ProductPriceCard]).
class ProductPriceListView extends StatefulWidget {
  const ProductPriceListView({super.key});

  @override
  State<ProductPriceListView> createState() => _ProductPriceListView();
}

class _ProductPriceListView extends State<ProductPriceListView> {
  late final ProductPriceListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductPriceListViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.inicialData(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Confirma e remove os itens marcados (mesmo fluxo da lista de itens
  /// do orçamento).
  Future<void> _confirmDelete() async {
    final count = _viewModel.selectedCount;
    final confirm = await showConfirmBottomModal(
      context,
      title: ProductPtString.confirmRemoveTitle(count),
      message: ProductPtString.confirmRemoveMessage,
    );
    if (!confirm || !mounted) return;
    final ok = await _viewModel.deleteSelected();
    if (!mounted) return;
    if (ok) {
      AlertSnackBar.success(
        context,
        ProductPtString.doneTitle,
        ProductPtString.deleteSuccess,
      );
    } else {
      AlertSnackBar.error(
        context,
        ProductPtString.errorTitle,
        ProductPtString.deleteError,
      );
    }
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.selectionMode) {
          return FloatingActionButton.extended(
            heroTag: 'delete',
            onPressed: _viewModel.deleting ? null : _confirmDelete,
            backgroundColor: statusRejectedColor,
            elevation: 4,
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
                    : const Icon(
                      Icons.delete_outline_rounded,
                      color: whiteColor,
                    ),
            label: Text(
              ProductPtString.removeSelected(_viewModel.selectedCount),
              style: const TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );
        }
        return FloatingActionButton.extended(
          heroTag: 'adicionar_novo_item',
          onPressed: () => _viewModel.addNew(context),
          backgroundColor: buttonColor,
          elevation: 4,
          icon: const Icon(Icons.add, color: blackColor, size: 20),
          label: Text(
            ProductPtString.newItem,
            style: const TextStyle(
              color: blackColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }

  Widget _buildList({required List<ProductPriceModel> list}) {
    return Expanded(
      child: RefreshIndicator(
        color: refreshIndicatorColor,
        backgroundColor: bgColor,
        onRefresh: _viewModel.refresh,
        child: AppAdaptiveGrid(
          padding: const EdgeInsets.only(
            bottom: 160,
            left: 15,
            right: 15,
            top: 10,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return ProductPriceCard(
              item: list[index],
              moneyConvert: _viewModel.moneyConvert,
              selected: _viewModel.isSelected(list[index]),
              onTap: () {
                // No modo remoção o toque seleciona; fora dele, edita.
                if (_viewModel.toggleIfSelecting(list[index])) return;
                _viewModel.openCreator(context, item: list[index]);
              },
              onToggleSelect: () => _viewModel.toggleSelect(list[index]),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final list = _viewModel.found;
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              ProductPriceListHeader(
                searchController: _viewModel.searchController,
                onBack: () => Navigator.pop(context, true),
                onSearchChanged: (_) => _viewModel.onSearchChanged(),
              ),
              BudgetListItemsCategoryFilter(
                selected: _viewModel.category,
                onChanged: _viewModel.onCategoryChanged,
              ),
              if (_viewModel.selectionMode)
                ProductPriceSelectionBar(
                  count: _viewModel.selectedCount,
                  allSelected: _viewModel.allFilteredSelected,
                  onCancel: _viewModel.clearSelection,
                  onToggleAll: _viewModel.selectAllFiltered,
                ),
              _buildList(list: list),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}
