import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';

/// Implementação do repositório de compras in-app.
///
/// Espelha a API do [FlutterInappPurchase] para consumo via DI.
class InAppPurchaseRepositoryImpl implements InAppPurchaseRepository {
  @override
  Future<void> initConnection() => FlutterInappPurchase.instance.initConnection();

  @override
  Future<void> endConnection() => FlutterInappPurchase.instance.endConnection();

  @override
  Future<List<T>> fetchProducts<T extends ProductCommon>({
    required List<String> skus,
  }) async {
    return await FlutterInappPurchase.instance.fetchProducts<T>(
      skus: skus,
      type: ProductQueryType.Subs,
    );
  }

  @override
  Future<void> requestPurchaseWithBuilder(
    void Function(RequestPurchaseBuilder builder) build,
  ) async {
    await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
      build: build,
    );
  }

  @override
  Future<void> restorePurchases() =>
      FlutterInappPurchase.instance.restorePurchases();

  @override
  Future<void> acknowledgePurchaseAndroid(String purchaseToken) async {
    await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(purchaseToken);
  }

  @override
  Future<void> finishTransaction({
    required Purchase purchase,
    required bool isConsumable,
  }) async {
    await FlutterInappPurchase.instance.finishTransaction(
      purchase: purchase,
      isConsumable: isConsumable,
    );
  }

  @override
  Future<List<Purchase>> getAvailablePurchases() async {
    return await FlutterInappPurchase.instance.getAvailablePurchases();
  }

  @override
  Stream<Purchase> get purchaseUpdatedStream =>
      FlutterInappPurchase.instance.purchaseUpdatedListener;

  @override
  Stream<PurchaseError> get purchaseErrorStream =>
      FlutterInappPurchase.instance.purchaseErrorListener;
}
