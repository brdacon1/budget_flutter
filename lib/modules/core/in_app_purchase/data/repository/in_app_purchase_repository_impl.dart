import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:oflite/modules/core/in_app_purchase/data/datasource/in_app_purchase_remote_datasource.dart';
import 'package:oflite/modules/core/in_app_purchase/data/model/iap_product.dart';
import 'package:oflite/modules/core/in_app_purchase/data/model/iap_purchase.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';

/// Implementação do repositório de compras in-app.
///
/// Converte os tipos do plugin `in_app_purchase` nos models do módulo.
class InAppPurchaseRepositoryImpl implements InAppPurchaseRepository {
  final InAppPurchaseRemoteDataSource _dataSource;
  final bool _isAndroid;

  /// `ProductDetails` do último `fetchProducts`, por sku (para comprar).
  final Map<String, ProductDetails> _products = {};

  InAppPurchaseRepositoryImpl(this._dataSource, {bool? isAndroid})
    : _isAndroid = isAndroid ?? Platform.isAndroid;

  @override
  Future<void> initConnection() async {
    if (!await _dataSource.isAvailable()) {
      throw StateError('Loja indisponível');
    }
  }

  @override
  Future<List<IapProduct>> fetchProducts({required List<String> skus}) async {
    final response = await _dataSource.queryProductDetails(skus.toSet());
    if (kDebugMode && response.error != null) {
      debugPrint('[InAppPurchaseRepository] fetchProducts: ${response.error}');
    }

    final result = <IapProduct>[];
    for (final sku in skus) {
      final details = response.productDetails.where((p) => p.id == sku);
      if (details.isEmpty) continue;

      final chosen = _pickOffer(details);
      _products[sku] = chosen;
      result.add(_toProduct(chosen));
    }
    return result;
  }

  /// Android devolve um item por base plan/oferta: usa o índice 0, a mesma
  /// oferta (`subscriptionOffers.first`) que o pacote antigo comprava.
  ProductDetails _pickOffer(Iterable<ProductDetails> details) {
    for (final p in details) {
      if (p is! GooglePlayProductDetails || (p.subscriptionIndex ?? 0) == 0) {
        return p;
      }
    }
    return details.first;
  }

  IapProduct _toProduct(ProductDetails p) {
    if (p is GooglePlayProductDetails) {
      final offers = p.productDetails.subscriptionOfferDetails;
      final index = p.subscriptionIndex;
      final phases =
          offers != null && index != null && index < offers.length
              ? offers[index].pricingPhases
              : const <PricingPhaseWrapper>[];

      return IapProduct(
        id: p.id,
        // Fase recorrente (última), não a de trial/introdutória (primeira).
        displayPrice: phases.isNotEmpty ? phases.last.formattedPrice : p.price,
        offerTokenAndroid: p.offerToken,
      );
    }
    return IapProduct(id: p.id, displayPrice: p.price);
  }

  @override
  Future<void> requestSubscription(String sku) async {
    if (!_products.containsKey(sku)) await fetchProducts(skus: [sku]);

    final details = _products[sku];
    if (details == null) throw StateError('Produto não encontrado: $sku');

    final param =
        details is GooglePlayProductDetails
            ? GooglePlayPurchaseParam(productDetails: details)
            : PurchaseParam(productDetails: details);

    final sent = await _dataSource.buyNonConsumable(param);
    if (!sent) throw StateError('Compra não iniciada: $sku');
  }

  @override
  Future<void> restorePurchases() => _dataSource.restorePurchases();

  @override
  Future<void> acknowledgePurchaseAndroid(IapPurchase purchase) =>
      _complete(purchase);

  @override
  Future<void> finishTransaction(IapPurchase purchase) => _complete(purchase);

  Future<void> _complete(IapPurchase purchase) async {
    final source = purchase.source;
    if (source is PurchaseDetails && source.pendingCompletePurchase) {
      await _dataSource.completePurchase(source);
    }
  }

  @override
  Future<List<IapPurchase>> getAvailablePurchases() async {
    if (_isAndroid) {
      final response = await _dataSource.queryPastPurchasesAndroid();
      // Erro sem nenhuma compra → exceção (o chamador grava `false`).
      if (response.error != null && response.pastPurchases.isEmpty) {
        throw StateError('queryPastPurchases: ${response.error!.message}');
      }
      return response.pastPurchases.map(toPurchase).toList();
    }

    final entitlements = await _dataSource.currentEntitlementsIos();
    return entitlements.map(_fromEntitlement).toList();
  }

  IapPurchase _fromEntitlement(SK2Transaction t) => IapPurchase(
    productId: t.productId,
    purchaseToken: t.receiptData ?? '',
    isAutoRenewing: _notExpired(t.expirationDate),
    transactionDate: int.tryParse(t.purchaseDate) ?? 0,
    status: IapPurchaseStatus.purchased,
  );

  Stream<PurchaseDetails> get _purchases =>
      _dataSource.purchaseStream.expand((list) => list);

  @override
  Stream<IapPurchase> get purchaseUpdatedStream => _purchases
      .where(
        (p) =>
            p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored ||
            p.status == PurchaseStatus.pending,
      )
      .map(toPurchase);

  @override
  Stream<IapPurchase> get purchaseErrorStream => _purchases
      .where(
        (p) =>
            p.status == PurchaseStatus.error ||
            p.status == PurchaseStatus.canceled,
      )
      .map((p) {
        // Transação com erro também precisa ser completada, senão volta a
        // cada abertura do app.
        if (p.pendingCompletePurchase) {
          unawaited(_dataSource.completePurchase(p).catchError((_) {}));
        }
        return toPurchase(p);
      });

  /// Converte `PurchaseDetails` do plugin em [IapPurchase].
  @visibleForTesting
  IapPurchase toPurchase(PurchaseDetails p) {
    final status = switch (p.status) {
      // Restaurada = compra concluída (mesmo fluxo do pacote antigo).
      PurchaseStatus.purchased ||
      PurchaseStatus.restored => IapPurchaseStatus.purchased,
      PurchaseStatus.pending => IapPurchaseStatus.pending,
      PurchaseStatus.canceled => IapPurchaseStatus.cancelled,
      PurchaseStatus.error => IapPurchaseStatus.error,
    };

    if (p is GooglePlayPurchaseDetails) {
      final b = p.billingClientPurchase;
      return IapPurchase(
        productId: p.productID,
        purchaseToken: b.purchaseToken,
        // Mesmo dado da Billing do pacote antigo; pendente nunca é premium.
        isAutoRenewing:
            b.isAutoRenewing &&
            b.purchaseState == PurchaseStateWrapper.purchased,
        transactionDate: b.purchaseTime,
        status: status,
        needsCompletion: p.pendingCompletePurchase,
        source: p,
      );
    }

    // iOS: premium = assinatura comprada/restaurada e ainda vigente.
    final expiration = p is SK2PurchaseDetails ? p.expirationDate : null;
    return IapPurchase(
      productId: p.productID,
      purchaseToken: p.verificationData.serverVerificationData,
      isAutoRenewing:
          status == IapPurchaseStatus.purchased && _notExpired(expiration),
      transactionDate: int.tryParse(p.transactionDate ?? '') ?? 0,
      status: status,
      needsCompletion: p.pendingCompletePurchase,
      source: p,
    );
  }

  /// `expirationMillis` nulo = sem expiração informada.
  bool _notExpired(String? expirationMillis) {
    final millis = int.tryParse(expirationMillis ?? '');
    return millis == null || millis > DateTime.now().millisecondsSinceEpoch;
  }
}
