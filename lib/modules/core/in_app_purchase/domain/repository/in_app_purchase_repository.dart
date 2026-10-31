import 'dart:async';

import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/// Contrato para gerenciamento de compras in-app (assinaturas).
///
/// Abstrai o plugin `flutter_inapp_purchase`.
abstract class InAppPurchaseRepository {
  /// Inicializa a conexão com a loja (Google Play / App Store).
  Future<void> initConnection();

  /// Finaliza a conexão com a loja.
  Future<void> endConnection();

  /// Busca os produtos / assinaturas disponíveis para os [skus] informados.
  Future<List<T>> fetchProducts<T extends ProductCommon>({
    required List<String> skus,
  });

  /// Solicita a compra/assinatura via builder.
  Future<void> requestPurchaseWithBuilder(
    void Function(RequestPurchaseBuilder builder) build,
  );

  /// Restaura compras anteriores.
  Future<void> restorePurchases();

  /// Confirma (acknowledge) uma compra no Android.
  Future<void> acknowledgePurchaseAndroid(String purchaseToken);

  /// Finaliza uma transação (obrigatório no iOS).
  Future<void> finishTransaction({
    required Purchase purchase,
    required bool isConsumable,
  });

  /// Retorna compras disponíveis / pendentes.
  Future<List<Purchase>> getAvailablePurchases();

  /// Stream de compras bem-sucedidas.
  Stream<Purchase> get purchaseUpdatedStream;

  /// Stream de erros de compra.
  Stream<PurchaseError> get purchaseErrorStream;
}
