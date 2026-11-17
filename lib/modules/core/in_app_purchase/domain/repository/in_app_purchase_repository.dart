import 'dart:async';

import 'package:oflite/modules/core/in_app_purchase/data/model/iap_product.dart';
import 'package:oflite/modules/core/in_app_purchase/data/model/iap_purchase.dart';

/// Contrato para gerenciamento de compras in-app (assinaturas).
///
/// Abstrai o plugin `in_app_purchase`; só expõe models do módulo.
abstract class InAppPurchaseRepository {
  /// Verifica se a loja (Google Play / App Store) está disponível.
  Future<void> initConnection();

  /// Busca as assinaturas disponíveis para os [skus] informados.
  Future<List<IapProduct>> fetchProducts({required List<String> skus});

  /// Solicita a assinatura do [sku]. O resultado chega pelos streams.
  Future<void> requestSubscription(String sku);

  /// Restaura compras anteriores. O resultado chega pelos streams.
  Future<void> restorePurchases();

  /// Confirma (acknowledge) uma compra no Android.
  Future<void> acknowledgePurchaseAndroid(IapPurchase purchase);

  /// Finaliza uma transação (obrigatório no iOS).
  Future<void> finishTransaction(IapPurchase purchase);

  /// Assinaturas ativas do usuário na loja.
  Future<List<IapPurchase>> getAvailablePurchases();

  /// Compras concluídas/pendentes (restauradas chegam como `purchased`).
  Stream<IapPurchase> get purchaseUpdatedStream;

  /// Compras com erro ou canceladas pelo usuário.
  Stream<IapPurchase> get purchaseErrorStream;
}
