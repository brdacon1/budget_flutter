import 'package:flutter/widgets.dart';

/// Textos das notas fiscais / recibos de compra (chat + lista), pt/en.
class InvoiceStrings {
  const InvoiceStrings._();

  static bool get _isPt =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'pt';

  // --- Chat ---
  static String get askKind =>
      _isPt
          ? 'Você quer salvar um comprovante de pagamentos ou uma nota fiscal ao orçamento?'
          : 'Do you want to save a payment proof or an invoice to the budget?';
  static String get kindProof => _isPt ? 'Comprovantes' : 'Payment proofs';
  static String get kindInvoice => _isPt ? 'Nota fiscal' : 'Invoice';
  static String get askName =>
      _isPt ? 'Qual o nome da nota fiscal?' : 'What is the invoice name?';
  static String get nameRequired =>
      _isPt
          ? 'O nome é obrigatório. Qual o nome da nota fiscal?'
          : 'The name is required. What is the invoice name?';
  static String get askValue =>
      _isPt ? 'Qual o valor da nota fiscal?' : 'What is the invoice amount?';
  static String get saved =>
      _isPt
          ? 'Nota fiscal salva com sucesso ✅'
          : 'Invoice saved successfully ✅';
  static String get seeInvoices => _isPt ? 'Ver notas fiscais' : 'See invoices';
  static String get saveError =>
      _isPt
          ? 'Não consegui salvar a nota fiscal. Tente de novo.'
          : "Couldn't save the invoice. Try again.";
  static String get limitReached =>
      _isPt
          ? 'Esse orçamento já tem 15 notas fiscais. Escolha outro orçamento.'
          : 'This budget already has 15 invoices. Choose another budget.';
  static String limitWouldExceed(int count) =>
      _isPt
          ? 'Esse orçamento já tem $count de 15 notas fiscais e não cabem estes arquivos. Escolha outro orçamento.'
          : 'This budget already has $count of 15 invoices and these files do not fit. Choose another budget.';

  // --- Formulário ---
  static String get fieldName => _isPt ? 'Nome' : 'Name';
  static String get fieldValue => _isPt ? 'Valor' : 'Amount';
  static String get save => _isPt ? 'Salvar' : 'Save';
  static String get back => _isPt ? 'Voltar' : 'Back';

  // --- Lista ---
  static String get menuLabel => _isPt ? 'Notas fiscais' : 'Invoices';
  static String get totalLabel => _isPt ? 'Total a cobrar' : 'Total to charge';
  static String count(int n) =>
      _isPt
          ? '$n ${n == 1 ? 'nota fiscal' : 'notas fiscais'}'
          : '$n ${n == 1 ? 'invoice' : 'invoices'}';
  static String listCounter(int n) =>
      _isPt ? '$n de 15 notas fiscais' : '$n of 15 invoices';
  static String get empty =>
      _isPt
          ? 'Nenhuma nota fiscal ainda. Envie pelo chat 📎'
          : 'No invoices yet. Send one through the chat 📎';
  static String get deleteConfirm =>
      _isPt ? 'Excluir esta nota fiscal?' : 'Delete this invoice?';
  static String get deleteSuccess =>
      _isPt ? 'Nota fiscal excluída.' : 'Invoice deleted.';
  static String get loadError =>
      _isPt
          ? 'Não foi possível carregar as notas fiscais.'
          : 'Could not load the invoices.';
  static String get deleteError =>
      _isPt
          ? 'Não foi possível excluir a nota fiscal.'
          : 'Could not delete the invoice.';
}
