import 'package:flutter/material.dart';
import 'budget_list/presenter/budget_list_view.dart';

enum BudgetRoute { budgetList }

extension BudgetRouteExtension on BudgetRoute {
  String get path {
    switch (this) {
      case BudgetRoute.budgetList:
        return '/menu_tecnico';
    }
  }
}

final Map<String, WidgetBuilder> budgetRoutes = {
  BudgetRoute.budgetList.path: (_) => const BudgetListView(),
};
