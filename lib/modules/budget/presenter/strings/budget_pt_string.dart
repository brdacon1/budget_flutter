import 'package:flutter/widgets.dart';

/// Textos do módulo Budget internacionalizados.
class BudgetStrings {
  const BudgetStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get emptyStateTitle =>
      _isPt ? 'Você ainda não criou orçamentos' : 'You have not created any budgets yet';
}
