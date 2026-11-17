import 'package:flutter/widgets.dart';

/// Textos do módulo Budget internacionalizados.
class BudgetStrings {
  const BudgetStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get emptyStateTitle =>
      _isPt
          ? 'Você ainda não criou orçamentos'
          : 'You have not created any budgets yet';

  static String get screenTitle => _isPt ? 'Meus orçamentos' : 'My budgets';
  static String get searchPlaceholder =>
      _isPt ? 'Buscar cliente' : 'Search client';
  static String get newBudget => _isPt ? 'Novo orçamento' : 'New budget';
  static String get removeAll => _isPt ? 'Remover todos' : 'Remove all';
  static String get budgetNumber => _isPt ? 'Nº' : 'No.';
  static String get detailDate => _isPt ? 'Data' : 'Date';
  static String get detailStatus => 'Status';
  static String get detailPhone => _isPt ? 'Telefone' : 'Phone';
  static String get detailValue => _isPt ? 'Valor' : 'Value';
  static String get actionDelete => _isPt ? 'Excluir' : 'Delete';
  static String get actionSelected => _isPt ? 'Selecionado' : 'Selected';
  static String get actionDuplicate => _isPt ? 'Duplicar' : 'Duplicate';
  static String get actionOpen => _isPt ? 'Abrir' : 'Open';
}
