/// Produto/assinatura da loja, já normalizado entre Android e iOS.
class IapProduct {
  final String id;

  /// Preço recorrente formatado pela loja (nunca o da fase de trial).
  final String displayPrice;

  /// Token da oferta escolhida no Android; `null` no iOS.
  final String? offerTokenAndroid;

  const IapProduct({
    required this.id,
    required this.displayPrice,
    this.offerTokenAndroid,
  });
}
