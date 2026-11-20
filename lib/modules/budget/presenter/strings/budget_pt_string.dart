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
  static String get filterAllStatus => _isPt ? 'Todos' : 'All';

  /// Label do status persistido (o valor gravado nunca é traduzido).
  static String statusLabel(String status) => switch (status) {
    'APROVADO' => _isPt ? 'Aprovado' : 'Approved',
    'REPROVADO' => _isPt ? 'Reprovado' : 'Rejected',
    'FINALIZADO' => _isPt ? 'Finalizado' : 'Finished',
    _ => _isPt ? 'Pendente' : 'Pending',
  };
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

  // Itens do orçamento — modal de detalhes/quantidade
  static String get itemDetailTitle =>
      _isPt ? 'Detalhes do item' : 'Item details';
  static String get itemLabelDescription => _isPt ? 'Descrição' : 'Description';
  static String get itemLabelCategory => _isPt ? 'Categoria' : 'Category';
  static String get itemLabelMeasure => _isPt ? 'Unidade' : 'Unit';
  static String get itemLabelPrice => _isPt ? 'Preço unitário' : 'Unit price';
  static String get itemLabelQuantity => _isPt ? 'Quantidade' : 'Quantity';
  static String get itemLabelTotal => _isPt ? 'Total do item' : 'Item total';
  static String get itemQuantityError =>
      _isPt
          ? 'Informe uma quantidade maior que zero'
          : 'Enter a quantity greater than zero';
  static String get itemSaveQuantity =>
      _isPt ? 'Salvar quantidade' : 'Save quantity';
  static String get itemQuantitySuccessTitle =>
      _isPt ? 'Quantidade atualizada' : 'Quantity updated';
  static String get itemQuantitySuccessMessage =>
      _isPt
          ? 'O total do orçamento foi atualizado.'
          : 'The budget total has been updated.';
  static String get itemQuantityErrorTitle =>
      _isPt ? 'Não foi possível atualizar' : "Couldn't update";

  // --- Métricas do orçamento ---
  static String get metricsTitle => _isPt ? 'Métricas' : 'Metrics';
  static String metricsSubtitle(String id) =>
      _isPt ? 'Orçamento nº $id' : 'Budget #$id';
  static String get metricsBudgetTotal =>
      _isPt ? 'Total do orçamento' : 'Budget total';
  static String get metricsToReceive => _isPt ? 'A receber' : 'To receive';
  static String metricsReceivedPercent(int p) =>
      _isPt ? '$p% recebido' : '$p% received';
  static String get metricsItems => _isPt ? 'Itens' : 'Items';
  static String get metricsServices => _isPt ? 'Serviços' : 'Services';
  static String get metricsReceipts => _isPt ? 'Recibos' : 'Receipts';
  static String get metricsProofs => _isPt ? 'Comprovantes' : 'Proofs';
  static String get metricsReceived => _isPt ? 'Recebimentos' : 'Payments';
  static String metricsReceiptsCount(int n) =>
      _isPt ? '$n recibo(s) emitido(s)' : '$n receipt(s) issued';
  static String get metricsOthers => _isPt ? 'Outros' : 'Others';
  static String get metricsLoadError =>
      _isPt
          ? 'Não foi possível carregar as métricas.'
          : 'Could not load metrics.';
}
