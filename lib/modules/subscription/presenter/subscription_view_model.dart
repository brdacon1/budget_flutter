import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'package:oflite/shared/common/constants/environment.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/subscription/presenter/strings/subscription_pt_string.dart';

enum SubscriptionState { idle, loading, success, error }

class SubscriptionViewModel extends ChangeNotifier {
  final InAppPurchaseRepository _iap;

  SubscriptionViewModel({InAppPurchaseRepository? iapRepository})
    : _iap = iapRepository ?? getIt<InAppPurchaseRepository>();

  SubscriptionState state = SubscriptionState.idle;
  String? errorMessage;

  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;

  // SKU por plataforma, lido dos arquivos de ambiente
  String get _androidSku => Environment.instance.subscription.androidSku;
  String get _iosSku => Environment.instance.subscription.iosSku;

  String get sku => Platform.isAndroid ? _androidSku : _iosSku;

  /// Guarda os produtos buscados (para obter offerToken no Android)
  List<ProductSubscription> _availableProducts = [];

  List<ProductSubscription> get availableProducts => _availableProducts;

  bool get hasProducts => _availableProducts.isNotEmpty;

  String? get displayPrice =>
      _availableProducts.isNotEmpty
          ? _availableProducts.first.displayPrice
          : null;

  Future<void> init() async {
    state = SubscriptionState.idle;
    errorMessage = null;
    notifyListeners();

    try {
      await _iap.initConnection();

      final products = await _iap.fetchProducts<ProductSubscription>(
        skus: [sku],
      );

      _availableProducts = products;

      if (kDebugMode) {
        print('[SubscriptionViewModel] Produtos: ${products.length}');
        for (final p in products) {
          print('  • ${p.id} - ${p.displayPrice}');
          if (p is ProductSubscriptionAndroid) {
            for (final o in p.subscriptionOffers) {
              print('    offer: ${o.id} token: ${o.offerTokenAndroid}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[SubscriptionViewModel] Erro init: $e');
      // Não quebra o flow para não travar a UI no emulador
    }

    _purchaseUpdatedSubscription = _iap.purchaseUpdatedStream.listen(
      _onPurchaseUpdated,
    );
    _purchaseErrorSubscription = _iap.purchaseErrorStream.listen(
      _onPurchaseError,
    );
  }

  Future<void> requestSubscription() async {
    state = SubscriptionState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      // Android precisa do offerToken do produto buscado
      String? offerToken;
      if (Platform.isAndroid) {
        final product = _availableProducts
            .cast<ProductSubscription?>()
            .firstWhere((p) => p?.id == sku, orElse: () => null);

        if (product != null && product is ProductSubscriptionAndroid) {
          if (product.subscriptionOffers.isNotEmpty) {
            offerToken = product.subscriptionOffers.first.offerTokenAndroid;
          }
        }

        if (offerToken == null) {
          throw Exception(SubscriptionStrings.offerTokenError(sku));
        }
      }

      await _iap.requestPurchaseWithBuilder((builder) {
        builder.type = ProductQueryType.Subs;

        if (Platform.isAndroid) {
          builder.android.skus = [sku];
          builder.android.offerToken = offerToken;
        } else {
          builder.ios.sku = sku;
        }
      });
      // Sucesso/erro vem pelo listener
    } catch (e) {
      state = SubscriptionState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _onPurchaseUpdated(Purchase purchase) async {
    try {
      _updateSubscriptionSession(
        autoRenewing: purchase.isAutoRenewing,
        purchaseToken: purchase.purchaseToken ?? '',
        productId: purchase.productId,
      );

      if (purchase.purchaseState == PurchaseState.Purchased) {
        // Android: acknowledge obrigatório em até 3 dias
        if (Platform.isAndroid &&
            purchase is PurchaseAndroid &&
            purchase.isAcknowledgedAndroid != true) {
          await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
            purchase.purchaseToken ?? '',
          );
        }

        // iOS: FINALIZAR TRANSAÇÃO é obrigatório!
        if (Platform.isIOS) {
          await _iap.finishTransaction(purchase: purchase, isConsumable: false);
        }

        state = SubscriptionState.success;
      } else if (purchase.purchaseState == PurchaseState.Pending) {
        state = SubscriptionState.success;
      } else {
        state = SubscriptionState.error;
        errorMessage = SubscriptionStrings.subscriptionNotCompleted;
      }
      notifyListeners();
    } catch (e) {
      state = SubscriptionState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _onPurchaseError(PurchaseError purchaseError) {
    if (purchaseError.code == ErrorCode.UserCancelled) {
      state = SubscriptionState.idle;
      errorMessage = null;
    } else {
      state = SubscriptionState.error;
      errorMessage = purchaseError.message;
    }
    notifyListeners();
  }

  /// Restaura compras anteriores (obrigatório ter na App Store)
  Future<void> restorePurchases() async {
    state = SubscriptionState.loading;
    notifyListeners();

    try {
      // iOS: restorePurchases dispara as transações pelo listener
      await _iap.restorePurchases();
      // O resultado vem pelo _purchaseUpdatedListener
    } catch (e) {
      state = SubscriptionState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkExistingSubscription() async {
    try {
      final result = await _iap.getAvailablePurchases();

      if (result.isNotEmpty) {
        final latest = result.reduce(
          (current, next) =>
              current.transactionDate > next.transactionDate ? current : next,
        );

        _updateSubscriptionSession(
          autoRenewing: latest.isAutoRenewing,
          purchaseToken: latest.purchaseToken ?? '',
          productId: latest.productId,
        );

        if (Platform.isAndroid &&
            latest is PurchaseAndroid &&
            latest.isAcknowledgedAndroid != true) {
          await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
            latest.purchaseToken ?? '',
          );
        }
      } else {
        _updateSubscriptionSession(autoRenewing: false, purchaseToken: '');
      }
    } catch (e) {
      _updateSubscriptionSession(autoRenewing: false, purchaseToken: '');
    }
  }

  void _updateSubscriptionSession({
    required bool autoRenewing,
    required String purchaseToken,
    String? productId,
  }) {
    final session = getIt<UserRepository>().selectUser.value ?? InfoUser();
    session.autoRenewing = autoRenewing;
    session.purchaseToken = purchaseToken;
    if (productId != null) session.productId = productId;
    getIt<UserRepository>().selectUser.value = session;
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }
}
