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

  static String get selectBudgetHint =>
      _isPt ? 'Selecione um orçamento' : 'Select a budget';

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
  static String get detailAddress => _isPt ? 'Endereço' : 'Address';
  static String get detailValue => _isPt ? 'Valor' : 'Value';
  static String get actionDelete => _isPt ? 'Excluir' : 'Delete';
  static String get actionDuplicate => _isPt ? 'Duplicar' : 'Duplicate';
  static String get actionMap => _isPt ? 'Mapa' : 'Map';
  static String get chooseMap => _isPt ? 'Abrir com' : 'Open with';
  static String get cancel => _isPt ? 'Cancelar' : 'Cancel';
  static String get mapErrorTitle => _isPt ? 'Erro!' : 'Error!';
  static String get mapErrorMessage =>
      _isPt ? 'Não foi possível abrir o mapa.' : 'Could not open the map.';

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
  static String get metricsProducts => _isPt ? 'Produtos' : 'Products';
  static String get metricsProofCoverage =>
      _isPt ? 'Comprovação dos recebimentos' : 'Payment proof coverage';
  static String metricsProofCoveragePercent(int p) =>
      _isPt
          ? '$p% do valor recebido tem comprovante'
          : '$p% of received value has proof';
  static String get metricsUnproven =>
      _isPt ? 'Recebido sem comprovante' : 'Received without proof';
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

  static String get customerBudgetsTitle =>
      _isPt ? 'Orçamentos do cliente' : 'Client budgets';
  static String get customerBudgetsEmpty =>
      _isPt
          ? 'Nenhum orçamento encontrado para este telefone'
          : 'No budgets found for this phone';
  static String get customerBudgetsNoPhone =>
      _isPt
          ? 'Cadastre o telefone do cliente na aba "Cliente" para ver os orçamentos vinculados.'
          : 'Add the client phone in the "Client" tab to see linked budgets.';
  static String get customerBudgetsLoadError =>
      _isPt
          ? 'Não foi possível carregar os orçamentos.'
          : 'Could not load budgets.';
  static String get createErrorTitle =>
      _isPt ? 'Não foi possível criar' : 'Could not create';
  static String get createErrorMessage =>
      _isPt
          ? 'Verifique sua conexão e tente novamente.'
          : 'Check your connection and try again.';

  // --- Tela de opções do orçamento ---
  static String get optionsTitle => _isPt ? 'Opções' : 'Options';
  static String get optionsSubtitle =>
      _isPt ? 'Opções do orçamento' : 'Budget options';
  static String get optionsSectionBudget => _isPt ? 'Orçamento' : 'Budget';
  static String get optionsSectionShare =>
      _isPt ? 'Compartilhar e PDF' : 'Share & PDF';
  static String get optionsSectionFinance => _isPt ? 'Financeiro' : 'Finance';

  static String get optionCustomerBudgetsDesc =>
      _isPt
          ? 'Veja todos os orçamentos deste cliente'
          : 'See all budgets for this client';
  static String get optionMetrics =>
      _isPt ? 'Métricas do orçamento' : 'Budget metrics';
  static String get optionMetricsDesc =>
      _isPt ? 'Totais, status e desempenho' : 'Totals, status and performance';
  static String get optionComments =>
      _isPt ? 'Inserir comentários' : 'Insert comments';
  static String get optionCommentsDesc =>
      _isPt ? 'Anotações e observações internas' : 'Internal notes and remarks';
  static String get optionShareLink =>
      _isPt ? 'Compartilhar link do orçamento' : 'Share budget link';
  static String get optionShareLinkDesc =>
      _isPt ? 'Envie ao cliente por link' : 'Send to the client via link';
  static String get optionPdfExecutive =>
      _isPt ? 'PDF Executivo' : 'Executive PDF';
  static String get optionPdfExecutiveDesc =>
      _isPt ? 'Layout limpo e objetivo' : 'Clean, concise layout';
  static String get optionPdfProfessional =>
      _isPt ? 'PDF Profissional' : 'Professional PDF';
  static String get optionPdfProfessionalDesc =>
      _isPt ? 'Layout completo e personalizável' : 'Full, customizable layout';
  static String get optionReceipt =>
      _isPt ? 'Recibo de pagamentos' : 'Payment receipt';
  static String get optionReceiptDesc =>
      _isPt ? 'Registre e emita recibos' : 'Record and issue receipts';
  static String get optionProofsDesc =>
      _isPt
          ? 'Anexe fotos e arquivos de pagamento'
          : 'Attach payment photos and files';

  static String get shareSubject => 'PDF';
  static String get watchAd => _isPt ? 'Ver anuncio' : 'Watch ad';
  static String get goPremium => _isPt ? 'Se tornar premium' : 'Go premium';
  static String get shareNotYetTitle => _isPt ? 'Ainda não!' : 'Not yet!';
  static String get shareSaveBefore =>
      _isPt
          ? 'Salve o orçamento antes de compartilhar o link.'
          : 'Save the budget before sharing the link.';
  static String get shareErrorTitle => _isPt ? 'Erro' : 'Error';
  static String get shareErrorGenerateLink =>
      _isPt
          ? 'Não foi possível gerar o link. Verifique sua conexão e tente novamente.'
          : 'Could not generate the link. Check your connection and try again.';
  static String get shareErrorShareLink =>
      _isPt
          ? 'Não foi possível compartilhar o link agora.'
          : 'Could not share the link now.';
}
