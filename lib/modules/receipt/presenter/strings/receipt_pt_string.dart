import 'package:flutter/widgets.dart';

/// Textos do módulo Receipt (recibo) internacionalizados.
///
/// Resolve o idioma a partir da **localidade do dispositivo**
/// ([WidgetsBinding.instance.platformDispatcher.locale]) e devolve a string
/// em `pt` (Português) ou `en` (Inglês, fallback para qualquer outra
/// localidade).
///
/// Uso: `ReceiptPtString.saveButton`, `ReceiptPtString.editTitle`, etc. Todos os
/// getters são `static`, então podem ser usados tanto na View quanto no
/// ViewModel (que só precisa de `package:flutter/widgets.dart`). Nenhum texto
/// visível ao usuário fica solto como literal nas telas de recibo — todos
/// passam por aqui, centralizando a tradução num arquivo só.
class ReceiptPtString {
  const ReceiptPtString._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  // --- Cabeçalho / títulos ---
  static String get editTitle => _isPt ? 'Editar recibo' : 'Edit receipt';

  static String get createTitle => _isPt ? 'Criar recibo' : 'Create receipt';

  static String get subtitle => _isPt ? 'Dados do recibo' : 'Receipt data';
  static String get closeKeyboard =>
      _isPt ? 'Fechar teclado' : 'Close keyboard';

  // --- Card de formulário ---
  static String get formCardTitle =>
      _isPt ? 'Insira dados do recibo' : 'Enter receipt data';

  static String get formCardSubtitleEdit =>
      _isPt ? 'Clique para editar recibo' : 'Click to edit receipt';

  static String get formCardSubtitleCreate =>
      _isPt ? 'Clique para criar recibo' : 'Click to create receipt';

  // --- Campos ---
  static String get numberHint => _isPt ? 'Número do recibo' : 'Receipt number';

  static String get dateHint => _isPt ? 'Data do recibo' : 'Receipt date';

  static String get descriptionHint =>
      _isPt ? 'Digite nome do recibo...' : 'Type the receipt name...';

  static String get formCardTitleSimple => _isPt ? 'Recibo' : 'Receipt';

  static String get descriptionLabel =>
      _isPt ? 'Descrição do recibo *' : 'Receipt description *';

  static String get descriptionExample =>
      _isPt ? 'Antecipação de transporte' : 'Transport advance';

  static String get descriptionRequired =>
      _isPt ? 'Informe a descrição do recibo' : 'Enter the receipt description';

  static String get summaryLabel => _isPt ? 'Recibo' : 'Receipt';

  static String createdOn(String date) =>
      _isPt ? 'Criado em $date' : 'Created on $date';

  static String get createButton => _isPt ? 'Criar recibo' : 'Create receipt';

  static String get saveChangesButton =>
      _isPt ? 'Salvar alterações' : 'Save changes';

  static String get saveErrorTitle =>
      _isPt ? 'Não foi possível salvar' : "Couldn't save";

  static String get saveErrorMessage =>
      _isPt
          ? 'Verifique sua conexão e tente novamente.'
          : 'Check your connection and try again.';

  static String get createdNextStep =>
      _isPt
          ? 'Recibo criado. Agora adicione os pagamentos.'
          : 'Receipt created. Now add the payments.';

  static String get changesSaved =>
      _isPt ? 'Alterações salvas' : 'Changes saved';

  static String get changesSavedMessage =>
      _isPt ? 'Dados do recibo atualizados.' : 'Receipt data updated.';

  // --- Botões ---
  static String get saveButton => _isPt ? 'SALVAR' : 'SAVE';

  static String get updateButton => _isPt ? 'ATUALIZAR' : 'UPDATE';

  static String get deleteLabel => _isPt ? 'Excluir' : 'Delete';

  static String get openLabel => _isPt ? 'Abrir' : 'Open';

  // --- Feedback (sucesso/erro) ---
  static String get doneTitle => _isPt ? 'Feito!' : 'Done!';

  static String get errorTitle => _isPt ? 'Erro!' : 'Error!';

  static String get createSuccess =>
      _isPt ? 'Recibo criado com sucesso!' : 'Receipt created successfully!';

  static String get updateSuccess =>
      _isPt
          ? 'Recibo atualizado com sucesso!'
          : 'Receipt updated successfully!';

  static String get deleteSuccess =>
      _isPt ? 'Recibo removido com sucesso!' : 'Receipt removed successfully!';

  static String get deleteError =>
      _isPt
          ? 'Problemas para remover o recibo!'
          : 'Problems removing the receipt!';

  // --- Lista de recibos ---
  static String get totalValueLabel =>
      _isPt ? 'Valor total do recibo: ' : 'Total receipt value: ';

  static String get dateLabel => _isPt ? 'Data do recibo: ' : 'Receipt date: ';

  static String get quantityLabel => _isPt ? 'Quantidade: ' : 'Quantity: ';

  static String get listTitle => _isPt ? 'Recibos' : 'Receipts';

  static String get listSubtitle =>
      _isPt ? 'Recibos do orçamento' : 'Budget receipts';

  static String get emptyList =>
      _isPt ? 'O orçamento não possui recibos' : 'This budget has no receipts';

  static String get receiptsTotalLabel => 'Total';

  static String receiptsCount(int n) =>
      _isPt
          ? '$n ${n == 1 ? 'recibo' : 'recibos'}'
          : '$n ${n == 1 ? 'receipt' : 'receipts'}';

  static String get newReceipt => _isPt ? 'Novo recibo' : 'New receipt';

  static String get receiptNumber => _isPt ? 'Nº' : 'No.';

  static String get detailDate => _isPt ? 'Data' : 'Date';

  static String get detailValue => _isPt ? 'Valor' : 'Value';

  // --- Abas ---
  static String get tabReceipt => _isPt ? 'Recibo' : 'Receipt';

  static String get tabPayments => _isPt ? 'Pagamentos' : 'Payments';

  static String get tabPdf => 'PDF';
}
