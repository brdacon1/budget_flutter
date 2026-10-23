import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:oflite/models/global_uid_user.dart' as UID;

enum SubscriptionState { idle, loading, success, error }

class SubscriptionViewModel extends ChangeNotifier {
  SubscriptionState state = SubscriptionState.idle;
  String? errorMessage;

  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;

  final List<String> productLists = Platform.isAndroid
      ? ['newproduct']
      : ['com.housestudio.oflite', 'com.housestudio.oflite'];

  Future<void> init() async {
    try {
      await FlutterInappPurchase.instance.initConnection();
      await FlutterInappPurchase.instance.fetchProducts<ProductSubscription>(
        skus: productLists,
        type: ProductQueryType.Subs,
      );
    } catch (_) {
      // Falha ao consultar produtos de assinatura é esperada no emulador
      // iOS (StoreKit não disponível) ou sem conectividade. Continua sem
      // interromper o fluxo — a UI já lida com estados vazios.
    }

    _purchaseUpdatedSubscription = FlutterInappPurchase
        .instance.purchaseUpdatedListener
        .listen(_onPurchaseUpdated);
    _purchaseErrorSubscription = FlutterInappPurchase
        .instance.purchaseErrorListener
        .listen(_onPurchaseError);
  }

  Future<void> requestSubscription(String productId) async {
    state = SubscriptionState.loading;
    notifyListeners();

    try {
      await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
        build: (builder) {
          builder
            ..type = ProductQueryType.Subs
            ..android.skus = [productId]
            ..ios.sku = productId;
        },
      );
    } catch (e) {
      state = SubscriptionState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _onPurchaseUpdated(Purchase purchase) async {
    try {
      UID.autoRenewing = purchase.isAutoRenewing;
      UID.purchaseToken = purchase.purchaseToken ?? '';
      UID.productId = purchase.productId;

      if (purchase.purchaseState == PurchaseState.Purchased) {
        if (Platform.isAndroid &&
            purchase is PurchaseAndroid &&
            purchase.isAcknowledgedAndroid != true) {
          await FlutterInappPurchase.instance
              .acknowledgePurchaseAndroid(purchase.purchaseToken ?? '');
        }
        state = SubscriptionState.success;
      } else if (purchase.purchaseState == PurchaseState.Pending) {
        state = SubscriptionState.success;
      } else {
        state = SubscriptionState.error;
        errorMessage = 'Assinatura não realizada';
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
      errorMessage = 'Assinatura não realizada';
    }
    notifyListeners();
  }

  Future<void> checkExistingSubscription() async {
    try {
      final resultSubscription =
          await FlutterInappPurchase.instance.getAvailablePurchases();

      if (resultSubscription.isNotEmpty) {
        final latestSubscription = resultSubscription.reduce(
          (current, next) =>
              (current.transactionDate) > (next.transactionDate)
                  ? current
                  : next,
        );

        UID.autoRenewing = latestSubscription.isAutoRenewing;
        UID.purchaseToken = latestSubscription.purchaseToken ?? '';
        UID.productId = latestSubscription.productId;

        if (Platform.isAndroid &&
            latestSubscription is PurchaseAndroid &&
            latestSubscription.isAcknowledgedAndroid != true) {
          await FlutterInappPurchase.instance
              .acknowledgePurchaseAndroid(latestSubscription.purchaseToken ?? '');
        }
      } else {
        UID.autoRenewing = false;
        UID.purchaseToken = '';
      }
    } catch (e) {
      UID.autoRenewing = false;
      UID.purchaseToken = '';
    }
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }
}
