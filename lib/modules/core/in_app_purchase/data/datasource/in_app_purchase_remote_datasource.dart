import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

/// Fonte externa para compras in-app (Google Play / App Store).
///
/// Não conhece entidades de negócio; espelha a API do plugin `in_app_purchase`.
class InAppPurchaseRemoteDataSource {
  final InAppPurchase _iap;

  InAppPurchaseRemoteDataSource({InAppPurchase? iap})
    : _iap = iap ?? InAppPurchase.instance;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _iap.queryProductDetails(ids);

  Future<bool> buyNonConsumable(PurchaseParam param) =>
      _iap.buyNonConsumable(purchaseParam: param);

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// Android: assinaturas ativas (Billing `queryPurchasesAsync`).
  Future<QueryPurchaseDetailsResponse> queryPastPurchasesAndroid() =>
      _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .queryPastPurchases();

  /// iOS: assinaturas vigentes (StoreKit 2 `Transaction.currentEntitlements`).
  /// Não pede senha da Apple ID, diferente de `restorePurchases`.
  Future<List<SK2Transaction>> currentEntitlementsIos() =>
      SK2Transaction.currentEntitlements();
}
