import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:oflite/modules/core/in_app_purchase/data/datasource/in_app_purchase_remote_datasource.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';

/// Implementação do repositório de compras in-app.
///
/// Espelha a API do [FlutterInappPurchase] para consumo via DI.
class InAppPurchaseRepositoryImpl implements InAppPurchaseRepository {
  final InAppPurchaseRemoteDataSource _dataSource;

  InAppPurchaseRepositoryImpl(this._dataSource);
  @override
  Future<void> initConnection() => _dataSource.initConnection();

  @override
  Future<void> endConnection() => _dataSource.endConnection();

  @override
  Future<List<T>> fetchProducts<T extends ProductCommon>({
    required List<String> skus,
  }) {
    return _dataSource.fetchProducts<T>(skus: skus);
  }

  @override
  Future<void> requestPurchaseWithBuilder(
    void Function(RequestPurchaseBuilder builder) build,
  ) {
    return _dataSource.requestPurchaseWithBuilder(build);
  }

  @override
  Future<void> restorePurchases() => _dataSource.restorePurchases();

  @override
  Future<void> acknowledgePurchaseAndroid(String purchaseToken) {
    return _dataSource.acknowledgePurchaseAndroid(purchaseToken);
  }

  @override
  Future<void> finishTransaction({
    required Purchase purchase,
    required bool isConsumable,
  }) {
    return _dataSource.finishTransaction(
      purchase: purchase,
      isConsumable: isConsumable,
    );
  }

  @override
  Future<List<Purchase>> getAvailablePurchases() {
    return _dataSource.getAvailablePurchases();
  }

  @override
  Stream<Purchase> get purchaseUpdatedStream => _dataSource.purchaseUpdatedStream;

  @override
  Stream<PurchaseError> get purchaseErrorStream => _dataSource.purchaseErrorStream;
}
