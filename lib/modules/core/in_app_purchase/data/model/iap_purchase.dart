enum IapPurchaseStatus { purchased, pending, error, cancelled }

/// Compra/assinatura da loja, já normalizada entre Android e iOS.
class IapPurchase {
  final String productId;
  final String purchaseToken;

  /// `true` só para assinatura comprada e ainda vigente.
  final bool isAutoRenewing;

  /// Milissegundos desde epoch (0 quando a loja não informa).
  final int transactionDate;

  final IapPurchaseStatus status;

  /// Precisa de acknowledge (Android) / finish (iOS).
  final bool needsCompletion;

  /// Objeto original do plugin, usado só pelo repository para completar a
  /// compra. ViewModels nunca leem este campo.
  final Object? source;

  const IapPurchase({
    required this.productId,
    required this.purchaseToken,
    required this.isAutoRenewing,
    required this.transactionDate,
    required this.status,
    this.needsCompletion = false,
    this.source,
  });

  @override
  String toString() => 'IapPurchase($productId, $status)';
}
