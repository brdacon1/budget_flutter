import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/domain/usecase/add_price_items_to_budget_usecase.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Estado do modal-picker da lista de preço: busca, itens selecionados
/// (carrinho), total e o [addAllCommand] que grava tudo no orçamento.
class ProductPricePickerViewModel extends ChangeNotifier {
  ProductPricePickerViewModel({required this.budgetId}) {
    addAllCommand = Command0<void>(_addAll);
  }

  final String budgetId;

  final ProductPriceRepository _productRepository =
      getIt<ProductPriceRepository>();
  final AddPriceItemsToBudgetUsecase _addItems =
      getIt<AddPriceItemsToBudgetUsecase>();
  final ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();

  final TextEditingController searchController = TextEditingController();

  late final Command0<void> addAllCommand;

  List<ProductPriceModel> _all = <ProductPriceModel>[];
  bool isLoading = true;

  /// Itens selecionados, por id do produto (mantém a ordem de seleção).
  final Map<String, ProductPriceModel> _cart = <String, ProductPriceModel>{};

  /// Filtro de categoria; `null` = todas.
  ItemCategory? category;

  List<ProductPriceModel> get found {
    final q = searchController.text.trim().toLowerCase();
    return _all.where((x) {
      if (category != null && ItemCategory.fromValue(x.categoria) != category) {
        return false;
      }
      return q.isEmpty || (x.descricao ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void onCategoryChanged(ItemCategory? value) {
    category = value;
    notifyListeners();
  }

  bool isSelected(ProductPriceModel item) => _cart.containsKey(item.id);

  double? quantityOf(ProductPriceModel item) => _cart[item.id]?.qtd;

  int get cartCount => _cart.length;

  double get cartTotal =>
      _cart.values.fold<double>(0, (sum, p) => sum + (p.total ?? 0));

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final result = await _productRepository.fetchProducts();
    _all =
        result is Ok<List<ProductPriceModel>>
            ? List<ProductPriceModel>.of(result.value)
            : <ProductPriceModel>[];
    isLoading = false;
    notifyListeners();
  }

  void onSearchChanged() => notifyListeners();

  /// Converte o texto digitado em quantidade; `null` se não for maior que 0.
  double? parseQuantity(String raw) {
    final value = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    return value;
  }

  String? validateQuantity(String raw) =>
      parseQuantity(raw) == null ? ProductPtString.qtyMustBePositive : null;

  void select(ProductPriceModel item, double quantity) {
    if (item.id == null || quantity <= 0) return;
    _cart[item.id!] = item.copyWith(
      qtd: quantity,
      idProduct: item.id,
      total: quantity * (item.preco ?? 0),
      selectProduct: true,
    );
    notifyListeners();
  }

  void unselect(ProductPriceModel item) {
    if (_cart.remove(item.id) != null) notifyListeners();
  }

  Future<Result<void>> _addAll() => _addItems(
    budgetId: budgetId,
    items: _cart.values.map((e) => e.toItemsBudget()).toList(),
  );

  @override
  void dispose() {
    addAllCommand.dispose();
    searchController.dispose();
    super.dispose();
  }
}
