import 'package:flutter/material.dart';

import 'modules/budget/budget_routes.dart';
import 'modules/login/login_routes.dart';
import 'modules/main_tab/main_tab_routes.dart';
import 'modules/pdf/pdf_routes.dart';
import 'modules/subscription/subscription_routes.dart';
import 'modules/terms_conditions/terms_conditions_routes.dart';

/// Enum central de rotas do aplicativo.
///
/// Cada módulo define seu próprio enum de rotas; aqui apenas agregamos
/// os caminhos para uso padronizado na navegação (`AppRoute.login.path`).
enum AppRoute {
  login,
  budgetList,
  subscription,
  mainTab,
  pdfConfig,
  termsConditions,
}

extension AppRouteExtension on AppRoute {
  String get path {
    switch (this) {
      case AppRoute.login:
        return LoginRoute.login.path;
      case AppRoute.budgetList:
        return BudgetRoute.budgetList.path;
      case AppRoute.subscription:
        return SubscriptionRoute.subscription.path;
      case AppRoute.mainTab:
        return MainTabRoute.mainTab.path;
      case AppRoute.pdfConfig:
        return PdfRoute.pdfConfig.path;
      case AppRoute.termsConditions:
        return TermsConditionsRoute.termsConditions.path;
    }
  }
}

/// Mapa central de rotas nomeadas, agregado via *spread* dos mapas de
/// cada módulo. Registrado no `MaterialApp.routes` de `main.dart`.
final Map<String, WidgetBuilder> appRoutes = {
  ...loginRoutes,
  ...budgetRoutes,
  ...subscriptionRoutes,
  ...mainTabRoutes,
  ...pdfRoutes,
  ...termsConditionsRoutes,
};
