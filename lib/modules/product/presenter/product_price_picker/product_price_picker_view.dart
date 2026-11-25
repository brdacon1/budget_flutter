import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

import 'components/product_price_picker_card.dart';
import 'components/product_price_picker_footer.dart';
import 'components/product_price_picker_quantity_bottom_modal_widget.dart';
import 'components/product_price_picker_header.dart';
import 'product_price_picker_view_model.dart';

/// Modal-tela (§19) para **selecionar** itens da lista de preço e
/// adicioná-los ao orçamento. Só seleção: não cria, edita nem exclui itens.
///
/// Tocar num item abre a quantidade (> 0); tocar num item marcado desmarca.
/// "Adicionar tudo" grava no orçamento e fecha com `pop(true)`.
class ProductPricePickerView extends StatefulWidget {
  const ProductPricePickerView({super.key, required this.budgetId});

  final String budgetId;

  @override
  State<ProductPricePickerView> createState() => _ProductPricePickerViewState();
}

class _ProductPricePickerViewState extends State<ProductPricePickerView> {
  /// Altura inicial: 87% da área visível.
  static const double _heightFactor = 0.87;

  /// Teto quando precisa crescer (ex.: teclado aberto): 90% da área visível,
  /// nunca passando da status bar.
  static const double _maxHeightFactor = 0.9;

  late final ProductPricePickerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductPricePickerViewModel(budgetId: widget.budgetId);
    _viewModel.addAllCommand.addListener(_onAddAllChanged);
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.addAllCommand.removeListener(_onAddAllChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onAddAllChanged() {
    final cmd = _viewModel.addAllCommand;
    if (!mounted || cmd.running) return;
    if (cmd.completed) {
      Navigator.of(context).pop(true);
    } else if (cmd.error) {
      AlertSnackBar.error(
        context,
        ProductPtString.errorTitle,
        ProductPtString.cartAddError,
      );
      cmd.clearResult();
    }
  }

  Future<void> _onItemTap(ProductPriceModel item) async {
    if (_viewModel.isSelected(item)) {
      _viewModel.unselect(item);
      return;
    }
    final qty = await showProductPricePickerQuantityBottomModal(
      context,
      validator: _viewModel.validateQuantity,
      parse: _viewModel.parseQuantity,
    );
    if (qty == null) return;
    _viewModel.select(item, qty);
  }

  void _addAll() {
    final cmd = _viewModel.addAllCommand;
    if (cmd.running || _viewModel.cartCount == 0) return;
    cmd.execute();
  }

  Widget _buildList() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: buttonColor));
    }
    final list = _viewModel.found;
    if (list.isEmpty) {
      return Center(
        child: Text(
          ProductPtString.pickerEmpty,
          style: GoogleFonts.heebo(color: emptyTextColor, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 4, bottom: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return ProductPricePickerCard(
          item: item,
          selected: _viewModel.isSelected(item),
          quantity: _viewModel.quantityOf(item),
          moneyConvert: _viewModel.moneyConvert,
          onTap: () => _onItemTap(item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final visible = mq.size.height - mq.viewInsets.bottom;
    final keyboardOpen = mq.viewInsets.bottom > 0;
    final factor = keyboardOpen ? _maxHeightFactor : _heightFactor;
    final height = (visible * factor).clamp(0.0, visible - mq.padding.top);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_viewModel, _viewModel.addAllCommand]),
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProductPricePickerHeader(
                  title: ProductPtString.listTitle,
                  searchController: _viewModel.searchController,
                  onSearchChanged: (_) => _viewModel.onSearchChanged(),
                  onClose: () => Navigator.of(context).pop(false),
                  category: _viewModel.category,
                  onCategoryChanged: _viewModel.onCategoryChanged,
                ),
                Expanded(child: _buildList()),
                if (_viewModel.cartCount > 0)
                  ProductPricePickerFooter(
                    total: _viewModel.moneyConvert.convertFromDouble(
                      _viewModel.cartTotal,
                    ),
                    count: _viewModel.cartCount,
                    loading: _viewModel.addAllCommand.running,
                    onAddAll: _addAll,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Abre o [ProductPricePickerView]. Retorna `true` quando os itens foram
/// adicionados ao orçamento (a tela de origem deve recarregar a lista).
Future<bool> showProductPricePickerBottomModal(
  BuildContext context, {
  required String budgetId,
}) async {
  final added = await showAppModal<bool>(
    context,
    builder: (context) => ProductPricePickerView(budgetId: budgetId),
  );
  return added ?? false;
}
