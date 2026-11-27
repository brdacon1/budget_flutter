import 'package:flutter/widgets.dart';

/// Textos do módulo Home internacionalizados.
class HomeStrings {
  const HomeStrings._();

  static bool get _isPt =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'pt';

  static String get tabTitle => _isPt ? 'Início' : 'Home';
  static String get appSubtitle =>
      _isPt ? 'Orçamentos e recibos' : 'Budgets and receipts';
  static String get heroTitle =>
      _isPt ? 'Total em orçamentos' : 'Total in budgets';
  static String heroCount(int n) =>
      _isPt
          ? '$n orçamento${n == 1 ? '' : 's'} gerado${n == 1 ? '' : 's'}'
          : '$n budget${n == 1 ? '' : 's'} created';
  static String get createBudgets =>
      _isPt ? 'Criar orçamentos' : 'Create budgets';
  static String get shareBudgets =>
      _isPt ? 'Compartilhar orçamentos' : 'Share budgets';
  static String get createReceipts =>
      _isPt ? 'Criar recibos' : 'Create receipts';
  static String get saveProofs =>
      _isPt ? 'Salvar notas/comprovantes' : 'Save invoices/proofs';
  static String get receiptsIssued =>
      _isPt ? 'Recibos gerados' : 'Receipts issued';
  static String get configurePdf =>
      _isPt ? 'Configurar PDF' : 'Configure PDF';
  static String get pdfType => _isPt ? 'Tipo do PDF' : 'PDF type';
  static String get clientBudgets =>
      _isPt ? 'Orçamentos do cliente' : 'Client budgets';
  static String get saveComments =>
      _isPt ? 'Cadastrar comentários' : 'Saved comments';
  static String get receiptList => _isPt ? 'Lista de recibos' : 'Receipt list';
  static String get budgetList => _isPt ? 'Lista de orçamentos' : 'Budget list';
  static String get reports => _isPt ? 'Relatórios' : 'Reports';
  static String get registerItems => _isPt ? 'Cadastrar itens' : 'Add items';
  static String get quickOverview => _isPt ? 'Visão geral' : 'Quick overview';
  static String get analysis =>
      _isPt ? 'Análise de recebimentos' : 'Receipts analysis';
  static String get loadError =>
      _isPt ? 'Não foi possível carregar os dados.' : 'Could not load data.';
}
