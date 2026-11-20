/// Tipo do arquivo do comprovante. O [value] é gravado no Firestore e
/// **nunca** muda (Regra Zero do i18n); o label vem das strings.
enum PaymentProofType {
  image('IMAGEM'),
  pdf('PDF');

  const PaymentProofType(this.value);

  final String value;

  static PaymentProofType fromValue(String? value) =>
      value == pdf.value ? pdf : image;
}

/// De onde veio o comprovante (valor gravado fixo).
enum PaymentProofOrigin {
  chat('CHAT'),
  share('COMPARTILHAMENTO');

  const PaymentProofOrigin(this.value);

  final String value;
}
