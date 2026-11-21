import 'package:flutter/widgets.dart';

/// Textos do módulo Dashboard internacionalizados.
class DashboardStrings {
  const DashboardStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get pageTitle => _isPt ? 'Dashboard' : 'Dashboard';

  static String get received => _isPt ? 'Recebido' : 'Received';

  static String get toReceive => _isPt ? 'Falta receber' : 'To receive';

  static String get receiptsComparison =>
      _isPt ? 'Recebimentos por mês' : 'Payments by month';

  static String get total => 'Total';

  static String get soldInMonth =>
      _isPt ? 'Vendidos no mês' : 'Sold this month';

  static String get soldHint =>
      _isPt
          ? 'Itens de orçamentos aprovados e finalizados'
          : 'Items from approved and finished budgets';

  static String quantity(double q) {
    final n =
        q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);
    return _isPt ? '$n un.' : '$n units';
  }

  static String get previousMonth => _isPt ? 'Mês anterior' : 'Previous month';

  static String get nextMonth => _isPt ? 'Próximo mês' : 'Next month';

  static String get loadError =>
      _isPt
          ? 'Não foi possível carregar o dashboard'
          : 'Could not load dashboard';

  static const _monthsPt = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  static const _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String shortMonth(DateTime d) =>
      (_isPt ? _monthsPt : _monthsEn)[d.month - 1];

  static String monthLabel(DateTime d) => '${shortMonth(d)}/${d.year}';

  static String get monthBudgets =>
      _isPt ? 'Orçamentos do mês' : 'Month budgets';

  static String get monthlyProgress =>
      _isPt ? 'Progresso mensal' : 'Monthly progress';

  static String get approved => _isPt ? 'Aprovados' : 'Approved';

  static String get disapproved => _isPt ? 'Reprovados' : 'Disapproved';

  static String get pending => _isPt ? 'Pendentes' : 'Pending';

  static String get finished => _isPt ? 'Finalizados' : 'Finished';

  static String get userFallback => _isPt ? 'Usuário' : 'User';

  static String get premium =>
      _isPt ? 'Seja Premium' : 'Go Premium';

  static String get deleteAccount =>
      _isPt ? 'Excluir conta' : 'Delete account';

  static String get logout => _isPt ? 'Sair' : 'Logout';

  /// Rótulo curto de eixo: R$ 0, R$ 850, R$ 2,5k.
  static String compactCurrency(double value) {
    final symbol = _isPt ? 'R\$' : '\$';
    if (value < 1000) return '$symbol ${value.round()}';
    final k = (value / 1000).toStringAsFixed(value < 10000 ? 1 : 0);
    final text = k.endsWith('.0') ? k.substring(0, k.length - 2) : k;
    return '$symbol ${_isPt ? text.replaceAll('.', ',') : text}k';
  }
}
