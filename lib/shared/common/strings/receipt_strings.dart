import 'package:flutter/widgets.dart';

/// Textos da área de recibo (lista + cadastro + abas) internacionalizados.
///
/// Resolve o idioma a partir da **localidade do dispositivo**
/// ([WidgetsBinding.instance.platformDispatcher.locale]) e devolve a string
/// em `pt` (Português) ou `en` (Inglês, fallback para qualquer outra
/// localidade).
///
/// Uso: `ReceiptStrings.saveButton`, `ReceiptStrings.editTitle`, etc. Todos os
/// getters são `static`, então podem ser usados tanto na View quanto no
/// ViewModel (que só precisa de `package:flutter/widgets.dart`). Nenhum texto
/// visível ao usuário fica solto como literal nas telas de recibo — todos
/// passam por aqui, centralizando a tradução num arquivo só.
class ReceiptStrings {
  const ReceiptStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  // --- Cabeçalho / títulos ---
  static String get editTitle => _isPt ? 'Editar recibo' : 'Edit receipt';
  static String get createTitle => _isPt ? 'Criar recibo' : 'Create receipt';
  static String get subtitle => _isPt ? 'Dados do recibo' : 'Receipt data';

  // --- Card de formulário ---
  static String get formCardTitle =>
      _isPt ? 'Insira dados do recibo' : 'Enter receipt data';
  static String get formCardSubtitleEdit =>
      _isPt ? 'Clique para editar recibo' : 'Click to edit receipt';
  static String get formCardSubtitleCreate =>
      _isPt ? 'Clique para criar recibo' : 'Click to create receipt';

  // --- Campos ---
  static String get numberHint =>
      _isPt ? 'Número do recibo' : 'Receipt number';
  static String get dateHint => _isPt ? 'Data do recibo' : 'Receipt date';
  static String get descriptionHint =>
      _isPt ? 'Digite nome do recibo...' : 'Type the receipt name...';

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
  static String get updateSuccess => _isPt
      ? 'Recibo atualizado com sucesso!'
      : 'Receipt updated successfully!';
  static String get deleteSuccess =>
      _isPt ? 'Recibo removido com sucesso!' : 'Receipt removed successfully!';
  static String get deleteError => _isPt
      ? 'Problemas para remover o recibo!'
      : 'Problems removing the receipt!';

  // --- Lista de recibos ---
  static String get listTitle => _isPt ? 'Recibos' : 'Receipts';
  static String get totalValueLabel =>
      _isPt ? 'Valor total do recibo: ' : 'Total receipt value: ';
  static String get dateLabel => _isPt ? 'Data do recibo: ' : 'Receipt date: ';
  static String get quantityLabel =>
      _isPt ? 'Quantidade: ' : 'Quantity: ';

  // --- Abas ---
  static String get tabReceipt => _isPt ? 'Recibo' : 'Receipt';
  static String get tabPayments => _isPt ? 'Pagamentos' : 'Payments';
  static String get tabPdf => 'PDF';
}
