import 'package:flutter/material.dart';
import 'budget_list/presenter/budget_list_view.dart';

enum BudgetRoute {
  budgetList,
  budgetCreator,
  budgetItems,
  budgetTab,
}

extension BudgetRouteExtension on BudgetRoute {
  String get path {
    switch (this) {
      case BudgetRoute.budgetList:
        return '/menu_tecnico';
      case BudgetRoute.budgetCreator:
        return '/budget/create';
      case BudgetRoute.budgetItems:
        return '/budget/items';
      case BudgetRoute.budgetTab:
        return '/budget/tab';
    }
  }
}

/// BudgetListView é a única tela sem argumentos exposta como rota.
/// As demais (creator, items, tab) exigem [CustomerInfo] — por ora
/// a navegação continua via `MaterialPageRoute`.
final Map<String, WidgetBuilder> budgetRoutes = {
  BudgetRoute.budgetList.path: (_) => const BudgetListView(),
};
