import 'package:flutter/widgets.dart';

/// Strings visíveis ao usuário do fluxo Web público de orçamento.
///
/// Segue o padrão `lib/common/strings/<area>_strings.dart` do SDD: centraliza
/// todo texto visível ao usuário num único arquivo por área, resolvendo o
/// idioma pela localidade do dispositivo e expondo getters `static`. Assim a
/// tradução fica num arquivo só, usável tanto pela View quanto pelo
/// ViewModel (que só precisa de `package:flutter/widgets.dart`).
///
/// As labels de orçamento (cliente, itens, status, etc.) são **idênticas** às
/// já usadas pelo aplicativo mobile, para manter o padrão visual/existente.
class BudgetWebStrings {
  BudgetWebStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  /// Sufixo de erro genérico quando o link é inválido/bloqueado.
  static String get blockedTitle => _locale.languageCode == 'pt'
      ? 'Acesso bloqueado'
      : 'Access blocked';

  static String get blockedMessage => _locale.languageCode == 'pt'
      ? 'O link de acesso ao orçamento é inválido ou expirou. Solicite um novo link.'
      : 'The budget access link is invalid or expired. Request a new link.';

  static String get phoneTitle => _locale.languageCode == 'pt'
      ? 'Validar acesso'
      : 'Validate access';

  static String get phoneSubtitle => _locale.languageCode == 'pt'
      ? 'Informe o telefone cadastrado no orçamento para visualizá-lo.'
      : 'Enter the phone number registered on the budget to view it.';

  static String get phoneHint => _locale.languageCode == 'pt'
      ? 'Telefone'
      : 'Phone';

  static String get phoneInvalid => _locale.languageCode == 'pt'
      ? 'Telefone não confere com o cadastrado no orçamento.'
      : 'The phone number does not match the one registered on the budget.';

  static String get phoneRequired => _locale.languageCode == 'pt'
      ? 'O telefone é obrigatório.'
      : 'Phone is required.';

  static String get validateButton => _locale.languageCode == 'pt'
      ? 'Acessar orçamento'
      : 'Access budget';

  static String get loading => _locale.languageCode == 'pt'
      ? 'Aguarde...'
      : 'Please wait...';

  // Tabs (espelham o app mobile: Cliente, Itens, PDF)
  static String get tabData => _locale.languageCode == 'pt' ? 'Meus dados' : 'My data';
  static String get tabItems => _locale.languageCode == 'pt' ? 'Itens' : 'Items';
  static String get tabPdf => 'PDF';

  // "Meus dados" — read-only. Labels idênticas às do app mobile.
  static String get sectionContact => 'Contato do cliente';
  static String get sectionInfo => 'Informações do orçamento';
  static String get sectionAddress => 'Endereço do cliente';

  static String get labelCustomerName => 'Nome do cliente';
  static String get labelPhone => 'Telefone';
  static String get labelStatus => 'Status do orçamento';
  static String get labelDate => 'Data do orçamento';
  static String get labelNumber => 'Número do orçamento';
  static String get labelCep => 'CEP';
  static String get labelStreet => 'Rua';
  static String get labelCity => 'Cidade';
  static String get labelNeighborhood => 'Bairro';

  // Itens
  static String get itemsTitle => 'Itens orçamentos';
  static String get itemsSearchHint => 'Digite a descrição do item...';

  // Seções colapsáveis na aba "Meus dados" (itens + comentários)
  static String get sectionItems => 'Itens do orçamento';
  static String get sectionComments => 'Comentários';
  static String get itemsEmpty => 'Nenhum item neste orçamento.';
  static String get commentsEmpty => 'Nenhum comentário neste orçamento.';
  static String get labelCommentDate => 'Data';
  static String get labelCommentText => 'Comentário';
  static String get labelPrice => 'Preço';
  static String get labelCategory => 'Categoria';
  static String get labelTotal => 'Total';
  static String get labelQuantity => 'Quantidade';
  static String get labelMeasure => 'Unidade de medida';
  static String get totalServices => 'Total Serviços';
  static String get totalProducts => 'Total produtos';
  static String get totalBudget => 'Total orçamento';

  // Aprovação
  static String get approveButton => 'Aprovar orçamento';
  static String get approveButtonApproved => _locale.languageCode == 'pt'
      ? 'Orçamento aprovado'
      : 'Budget approved';
  static String get approveButtonRejected => _locale.languageCode == 'pt'
      ? 'Orçamento reprovado'
      : 'Budget rejected';
  static String get approvalTitle => 'Aprovação do orçamento';
  static String get approvalMessage => _locale.languageCode == 'pt'
      ? 'Selecione o status do orçamento'
      : 'Select the budget status';
  static String get statusApproved => 'Aprovado';
  static String get statusRejected => 'Reprovado';
  static String get approvalSuccess => _locale.languageCode == 'pt'
      ? 'Orçamento atualizado com sucesso!'
      : 'Budget updated successfully!';
  static String get approvalError => _locale.languageCode == 'pt'
      ? 'Não foi possível atualizar o status do orçamento.'
      : 'Could not update the budget status.';

  // PDF
  static String get pdfTitle => 'PDF';
  static String get pdfEmpty => _locale.languageCode == 'pt'
      ? "Para visualizar o PDF do orçamento é necessário incluir apenas um produto ou serviço na aba 'Itens'"
      : 'To view the budget PDF, at least one product or service must be included';
  static String get pdfDownloadButton => _locale.languageCode == 'pt'
      ? 'BAIXAR PDF'
      : 'DOWNLOAD PDF';
  static String get pdfError => _locale.languageCode == 'pt'
      ? 'Não foi possível gerar o PDF.'
      : 'Could not generate the PDF.';
}
