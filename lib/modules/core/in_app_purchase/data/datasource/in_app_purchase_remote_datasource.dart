import 'dart:async';

import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/// Fonte externa para compras in-app (Google Play / App Store).
///
/// Não conhece entidades de negócio; espelha a API do plugin.
class InAppPurchaseRemoteDataSource {
  Future<void> initConnection() => FlutterInappPurchase.instance.initConnection();

  Future<void> endConnection() => FlutterInappPurchase.instance.endConnection();

  Future<List<T>> fetchProducts<T extends ProductCommon>({
    required List<String> skus,
  }) {
    return FlutterInappPurchase.instance.fetchProducts<T>(
      skus: skus,
      type: ProductQueryType.Subs,
    );
  }

  Future<void> requestPurchaseWithBuilder(
    void Function(RequestPurchaseBuilder builder) build,
  ) {
    return FlutterInappPurchase.instance.requestPurchaseWithBuilder(build: build);
  }

  Future<void> restorePurchases() => FlutterInappPurchase.instance.restorePurchases();

  Future<void> acknowledgePurchaseAndroid(String purchaseToken) {
    return FlutterInappPurchase.instance.acknowledgePurchaseAndroid(purchaseToken);
  }

  Future<void> finishTransaction({
    required Purchase purchase,
    required bool isConsumable,
  }) {
    return FlutterInappPurchase.instance.finishTransaction(
      purchase: purchase,
      isConsumable: isConsumable,
    );
  }

  Future<List<Purchase>> getAvailablePurchases() {
    return FlutterInappPurchase.instance.getAvailablePurchases();
  }

  Stream<Purchase> get purchaseUpdatedStream =>
      FlutterInappPurchase.instance.purchaseUpdatedListener;

  Stream<PurchaseError> get purchaseErrorStream =>
      FlutterInappPurchase.instance.purchaseErrorListener;
}
