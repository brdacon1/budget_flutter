import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

TextEditingController searchController = TextEditingController();

class BudgetListItemsViewModel extends ChangeNotifier {
  final CustomerInfo item;

  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final ProductPriceRepository _productRepository =
      getIt<ProductPriceRepository>();

  BudgetListItemsViewModel({required this.item});

  var budgets = <ItemsBudget>[];
  var deleteItens = <ItemsBudget>[];

  ItemsBudget newItemsBudget = ItemsBudget();
  ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  double totalProducts = 0;
  double totalServices = 0;
  double totalBudget = 0;
  int countProduct = 0;
  int countService = 0;

  Future<void> getListItens() async {
    budgets.clear();
    totalProducts = 0;
    totalServices = 0;
    totalBudget = 0;
    countProduct = 0;
    countService = 0;

    final result = await _budgetRepository.fetchBudgetItems(
      item.id!,
      forceRefresh: true,
    );
    if (result is Ok<List<ItemsBudget>>) {
      budgets = result.value;
      for (var o in budgets) {
        o.checkBox = false;
      }
    }

    for (int index = 0; index < budgets.length; index++) {
      double total = budgets[index].total ?? 0;
      if (budgets[index].category == 'Produtos') {
        totalProducts += total;
        countProduct++;
      } else if (budgets[index].category == 'Serviços') {
        totalServices += total;
        countService++;
      }
      totalBudget += total;
    }
    final currentSelectBudget = _budgetRepository.selectBudget.value;
    if (currentSelectBudget != null &&
        currentSelectBudget.totalValue != totalBudget) {
      _budgetRepository.selectBudget.value = item.copyWith(
        totalValue: totalBudget,
      );
      // Atualiza o orçamento com o total recalculado
      final budgetUpdate = item.copyWith(totalValue: totalBudget);
      await _budgetRepository.updateBudget(budgetUpdate);
    }

    notifyListeners();
  }

  Future<bool> deleteData() async {
    final result = await _budgetRepository.deleteBudgetItems(
      item.id!,
      deleteItens,
    );
    if (result is Ok<void>) {
      deleteItens.clear();
      deleteVisible = false;
    }
    return result is Ok<void>;
  }

  void onSearchTextChanged(String value) {
    notifyListeners();
  }

  List<ItemsBudget> getFilteredData() {
    if (searchController.text.isEmpty) {
      return budgets;
    } else {
      return budgets
          .where(
            (x) => x.description!.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }
  }

  void toggleDeleteItem(int index) {
    if (!getFilteredData()[index].checkBox!) {
      getFilteredData()[index].checkBox = true;
      getFilteredData()[index].selectProduct = false;
      getFilteredData()[index].indice = index;
      deleteItens.add(getFilteredData()[index]);
      if (deleteItens.isNotEmpty) {
        deleteVisible = true;
      }
    }
    notifyListeners();
  }

  void removeDeleteItem(ItemsBudget item) {
    getFilteredData()[item.indice].checkBox = false;
    deleteItens.remove(item);
    if (deleteItens.isEmpty) {
      deleteVisible = false;
      checkBoxAppear = false;
    }
    notifyListeners();
  }

  void clearDeleteItens() {
    deleteItens.clear();
    deleteVisible = false;
    checkBoxAppear = false;
    notifyListeners();
  }

  Future<int> getProductCount() async {
    final result = await _productRepository.getProductCount();
    return result;
  }
}
