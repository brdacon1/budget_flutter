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
  static String get budgetNumber => _isPt ? 'Nº' : 'No.';
  static String get detailDate => _isPt ? 'Data' : 'Date';
  static String get detailStatus => 'Status';
  static String get detailPhone => _isPt ? 'Telefone' : 'Phone';
  static String get detailValue => _isPt ? 'Valor' : 'Value';
  static String get actionDelete => _isPt ? 'Excluir' : 'Delete';
  static String get actionDuplicate => _isPt ? 'Duplicar' : 'Duplicate';
  static String get actionOpen => _isPt ? 'Abrir' : 'Open';

  static String get selectAll => _isPt ? 'Selecionar todos' : 'Select all';
  static String get clearAll => _isPt ? 'Limpar' : 'Clear';
  static String get cancelSelection =>
      _isPt ? 'Cancelar seleção' : 'Cancel selection';
  static String selectedCount(int n) =>
      _isPt
          ? (n == 1 ? '1 selecionado' : '$n selecionados')
          : (n == 1 ? '1 selected' : '$n selected');
  static String removeCount(int n) => _isPt ? 'Remover ($n)' : 'Remove ($n)';
  static String removeTitle(int n) =>
      _isPt
          ? (n == 1 ? 'Remover orçamento' : 'Remover $n orçamentos')
          : (n == 1 ? 'Remove budget' : 'Remove $n budgets');
  static String get removeMessage =>
      _isPt
          ? 'Essa ação não pode ser desfeita.'
          : 'This action cannot be undone.';
  static String get removeSuccessTitle => _isPt ? 'Tudo certo!' : 'All set!';
  static String get removeSuccessMessage =>
      _isPt
          ? 'Orçamentos removidos com sucesso!'
          : 'Budgets removed successfully!';
  static String get removeErrorTitle =>
      _isPt ? 'Não foi possível remover' : "Couldn't remove";
  static String get removeErrorMessage =>
      _isPt
          ? 'Verifique sua conexão e tente novamente.'
          : 'Check your connection and try again.';
}
