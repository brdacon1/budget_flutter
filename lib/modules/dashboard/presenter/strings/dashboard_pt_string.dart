import 'package:flutter/widgets.dart';

/// Textos do módulo Dashboard internacionalizados.
class DashboardStrings {
  const DashboardStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get pageTitle => _isPt ? 'Dashboard' : 'Dashboard';

  static String get recentBudgets =>
      _isPt ? 'Orçamentos recentes' : 'Recent budgets';

  static String get monthBudgets =>
      _isPt ? 'Orçamentos do mês' : 'Month budgets';

  static String get weeklyProgress =>
      _isPt ? 'Progresso semanal' : 'Weekly progress';

  static String get weeklyResult =>
      _isPt ? 'Resultado semanal' : 'Weekly result';

  static String get approved => _isPt ? 'Aprovados' : 'Approved';

  static String get disapproved => _isPt ? 'Reprovados' : 'Disapproved';

  static String get pending => _isPt ? 'Pendentes' : 'Pending';

  static String get finished => _isPt ? 'Finalizados' : 'Finished';

  static String get userFallback => _isPt ? 'Usuário' : 'User';

  static String get logout => _isPt ? 'Sair' : 'Logout';

  static String get search => _isPt ? 'Pesquisar' : 'Search';

  static String get clientColumn => _isPt ? 'Cliente' : 'Customer';

  static String get dateColumn => _isPt ? 'Data' : 'Date';

  static String get numberColumn => _isPt ? 'Número' : 'Number';

  static String weekLabel(int week) =>
      _isPt ? 'Sem. $week' : 'Week $week';

  static String currencyLabel(int value) {
    if (_isPt) {
      return 'R\$ ${value}k';
    }
    return r'$ ${value}k';
  }
}
