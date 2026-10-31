import 'package:flutter/material.dart';
import 'budget_web/budget_web_app/budget_web_app_view.dart';

enum WebBudgetRoute { webBudgetApp, webBudgetAuth, webBudgetData }

extension WebBudgetRouteExtension on WebBudgetRoute {
  String get path {
    switch (this) {
      case WebBudgetRoute.webBudgetApp:
        return '/web/app';
      case WebBudgetRoute.webBudgetAuth:
        return '/web/auth';
      case WebBudgetRoute.webBudgetData:
        return '/web/data';
    }
  }
}

/// BudgetWebAppView é a raiz do fluxo Web — interpreta a URL base.
/// As demais telas do fluxo Web recebem parâmetros via construtor.
final Map<String, WidgetBuilder> webBudgetRoutes = {
  WebBudgetRoute.webBudgetApp.path: (_) => const BudgetWebAppView(),
};
