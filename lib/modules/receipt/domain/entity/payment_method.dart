import 'package:oflite/modules/receipt/presenter/strings/payment_pt_string.dart';

/// Forma de pagamento.
///
/// [value] é o texto gravado em `METODO` — fixo, NUNCA traduzir (Regra Zero).
/// [label] é o texto exibido na tela (pt/en).
enum PaymentMethod {
  cash('Dinheiro'),
  pix('PIX'),
  credit('Crédito'),
  debit('Débito');

  final String value;
  const PaymentMethod(this.value);

  String get label => switch (this) {
    PaymentMethod.cash => PaymentStrings.methodCash,
    PaymentMethod.pix => 'PIX',
    PaymentMethod.credit => PaymentStrings.methodCredit,
    PaymentMethod.debit => PaymentStrings.methodDebit,
  };

  /// Lê `METODO` aceitando legados gravados traduzidos (`Cash`, `Credit`...).
  /// Desconhecido → `null`.
  static PaymentMethod? fromValue(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'dinheiro':
      case 'cash':
        return PaymentMethod.cash;
      case 'pix':
        return PaymentMethod.pix;
      case 'crédito':
      case 'credito':
      case 'credit':
        return PaymentMethod.credit;
      case 'débito':
      case 'debito':
      case 'debit':
        return PaymentMethod.debit;
    }
    return null;
  }

  /// Label de um valor gravado (desconhecido aparece como está).
  static String labelOf(String? raw) => fromValue(raw)?.label ?? (raw ?? '');
}
