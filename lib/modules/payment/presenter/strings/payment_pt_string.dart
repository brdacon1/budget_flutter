import 'package:flutter/widgets.dart';

/// Textos do módulo Payment internacionalizados.
class PaymentStrings {
  const PaymentStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get saveButton => _isPt ? 'SALVAR' : 'SAVE';

  static String get updateButton => _isPt ? 'ATUALIZAR' : 'UPDATE';

  static String get createPaymentTitle =>
      _isPt ? 'Criar pagamento' : 'Create payment';

  static String get editPaymentTitle =>
      _isPt ? 'Editar pagamento' : 'Edit payment';

  static String get defaultPaymentType =>
      _isPt ? 'Dinheiro' : 'Cash';

  static List<String> get paymentTypeOptions => _isPt
      ? ['Crédito', 'Débito', 'Dinheiro', 'PIX']
      : ['Credit', 'Debit', 'Cash', 'PIX'];

  static String get selectPaymentTypeTitle =>
      _isPt ? 'Tipo do pagamento' : 'Payment type';

  static String get paymentDataTitle =>
      _isPt ? 'Dados do pagamento' : 'Payment data';

  static String get insertPaymentData =>
      _isPt ? 'Insira dados do pagamento' : 'Enter payment data';

  static String get paymentHint =>
      _isPt ? 'Definir pagamento' : 'Define payment';

  static String get priceHint => _isPt ? 'Preço' : 'Price';

  static String get paymentDescriptionHint => _isPt
      ? 'Escreva a descrição do pagamento...'
      : 'Write the payment description...';

  static String get paymentsTitle =>
      _isPt ? 'Pagamentos' : 'Payments';

  static String get deleteLabel => _isPt ? 'Excluir' : 'Delete';

  static String get editLabel => _isPt ? 'Editar' : 'Edit';

  static String get doneTitle => _isPt ? 'Feito!' : 'Done!';

  static String get errorTitle => _isPt ? 'Erro!' : 'Error!';

  static String get paymentCreated => _isPt
      ? 'Pagamento criado com sucesso!'
      : 'Payment created successfully!';

  static String get paymentUpdated => _isPt
      ? 'Pagamento atualizado com sucesso!'
      : 'Payment updated successfully!';

  static String get paymentRemoved => _isPt
      ? 'Pagamento removido com sucesso!'
      : 'Payment removed successfully!';

  static String get errorRemovePayment => _isPt
      ? 'Problemas para remover o pagamento'
      : 'Problems removing the payment';

  static String get receiptNotSaved =>
      _isPt ? 'Recibo não salvo' : 'Receipt not saved';

  static String get receiptNotSavedMessage => _isPt
      ? 'Salve o recibo na aba "Recibo" antes de adicionar pagamentos.'
      : 'Save the receipt in the "Receipt" tab before adding payments.';

  static String paymentValueLabel(String value) =>
      _isPt ? 'Valor do pagamento: $value' : 'Payment value: $value';

  static String paymentMethodLabel(String method) =>
      _isPt ? 'Método do pagamento: $method' : 'Payment method: $method';
}
