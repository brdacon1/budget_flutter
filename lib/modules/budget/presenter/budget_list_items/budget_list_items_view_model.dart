import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class BudgetListItemsViewModel extends ChangeNotifier {
  final CustomerInfo item;

  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final ProductPriceRepository _productRepository =
      getIt<ProductPriceRepository>();
  final ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();
  BudgetListItemsViewModel({required this.item});

  final searchController = TextEditingController();

  List<ItemsBudget> budgets = <ItemsBudget>[];

  /// Itens marcados pelo check circular para remoção.
  final Set<ItemsBudget> selected = <ItemsBudget>{};

  /// Filtro por categoria; `null` = Todos.
  ItemCategory? category;

  bool loading = true;
  bool deleting = false;
  ItemsBudget newItemsBudget = ItemsBudget();
  double totalProducts = 0;
  double totalServices = 0;
  double totalBudget = 0;

  bool get selectionMode => selected.isNotEmpty;

  bool isSelected(ItemsBudget i) => selected.contains(i);

  Future<void> getListItens() async {
    final result = await _budgetRepository.fetchBudgetItems(
      item.id!,
      forceRefresh: true,
    );

    // Cópia própria: não compartilhar a instância do cache do repositório.
    budgets =
        result is Ok<List<ItemsBudget>>
            ? List<ItemsBudget>.of(result.value)
            : <ItemsBudget>[];
    // Mantém a seleção (por id) entre recargas: as instâncias são novas.
    final keepIds = selected.map((e) => e.id).toSet();
    selected
      ..clear()
      ..addAll(budgets.where((b) => keepIds.contains(b.id)));
    loading = false;

    totalProducts = 0;
    totalServices = 0;
    totalBudget = 0;
    for (final b in budgets) {
      final total = b.total ?? 0;
      final category = ItemCategory.fromValue(b.category);
      if (category == ItemCategory.products) {
        totalProducts += total;
      } else if (category == ItemCategory.services) {
        totalServices += total;
      }
      totalBudget += total;
    }

    final currentSelectBudget = _budgetRepository.selectBudget.value;
    if (currentSelectBudget != null &&
        currentSelectBudget.totalValue != totalBudget) {
      final budgetUpdate = item.copyWith(totalValue: totalBudget);
      _budgetRepository.selectBudget.value = budgetUpdate;
      await _budgetRepository.updateBudget(budgetUpdate);
    }

    notifyListeners();
  }

  List<ItemsBudget> get filteredItems {
    final q = searchController.text.trim().toLowerCase();
    return budgets.where((x) {
      if (category != null && ItemCategory.fromValue(x.category) != category) {
        return false;
      }
      return q.isEmpty || (x.description ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void onCategoryChanged(ItemCategory? value) {
    category = value;
    notifyListeners();
  }

  void onSearchTextChanged(String _) => notifyListeners();

  void toggleSelect(ItemsBudget i) {
    if (!selected.remove(i)) selected.add(i);
    notifyListeners();
  }

  void selectAllFiltered() {
    final items = filteredItems;
    if (items.every(selected.contains)) {
      selected.removeAll(items);
    } else {
      selected.addAll(items);
    }
    notifyListeners();
  }

  void clearSelection() {
    selected.clear();
    notifyListeners();
  }

  /// Remove os itens selecionados. Retorna `true` em caso de sucesso.
  Future<bool> deleteSelected() async {
    if (selected.isEmpty || deleting) return false;
    deleting = true;
    notifyListeners();
    final result = await _budgetRepository.deleteBudgetItems(
      item.id!,
      selected.toList(),
    );
    deleting = false;
    if (result is Ok<void>) {
      await getListItens();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<int> getProductCount() => _productRepository.getProductCount();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
