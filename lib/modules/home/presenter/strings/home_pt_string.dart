import 'package:flutter/widgets.dart';

/// Textos do módulo Home internacionalizados.
class HomeStrings {
  const HomeStrings._();

  static bool get _isPt =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'pt';

  static String greeting(DateTime now) {
    final h = now.hour;
    if (_isPt) {
      return h < 12
          ? 'Bom dia,'
          : h < 18
          ? 'Boa tarde,'
          : 'Boa noite,';
    }
    return h < 12
        ? 'Good morning,'
        : h < 18
        ? 'Good afternoon,'
        : 'Good evening,';
  }

  static String get tabTitle => _isPt ? 'Início' : 'Home';
  static String get appSubtitle =>
      _isPt ? 'Orçamentos e recibos' : 'Budgets and receipts';
  static String get heroTitle =>
      _isPt ? 'Aprovados no mês' : 'Approved this month';
  static String heroCount(int n) =>
      _isPt
          ? '$n orçamento${n == 1 ? '' : 's'}'
          : '$n budget${n == 1 ? '' : 's'}';
  static String get createBudgets =>
      _isPt ? 'Criar orçamentos' : 'Create budgets';
  static String get budgetList => _isPt ? 'Lista de orçamentos' : 'Budget list';
  static String get reports => _isPt ? 'Relatórios' : 'Reports';
  static String get registerItems => _isPt ? 'Cadastrar itens' : 'Add items';
  static String get quickOverview => _isPt ? 'Visão geral' : 'Quick overview';
  static String get analysis =>
      _isPt ? 'Análise de recebimentos' : 'Receipts analysis';
  static String get loadError =>
      _isPt ? 'Não foi possível carregar os dados.' : 'Could not load data.';
}
