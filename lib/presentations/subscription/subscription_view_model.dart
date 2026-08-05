import 'dart:async';
import 'dart:convert';
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
    await FlutterInappPurchase.instance.initialize();
    await FlutterInappPurchase.instance.getSubscriptions(productLists);

    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen(_onPurchaseUpdated);
    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen(_onPurchaseError);
  }

  Future<void> requestSubscription(String productId) async {
    state = SubscriptionState.loading;
    notifyListeners();

    try {
      await FlutterInappPurchase.instance.requestSubscription(productId);
    } catch (e) {
      state = SubscriptionState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _onPurchaseUpdated(PurchasedItem? productItem) async {
    if (productItem == null) return;

    try {
      final data = jsonDecode(productItem.transactionReceipt ?? '{}');
      final acknowledgedValue = data['acknowledged'] ?? false;

      UID.autoRenewing = data['autoRenewing'] ?? false;
      UID.purchaseToken = data['purchaseToken'] ?? '';
      UID.productId = data['productId'] ?? '';

      if (!acknowledgedValue) {
        await FlutterInappPurchase.instance
            .acknowledgePurchaseAndroid(productItem.purchaseToken ?? '');
      }

      state = SubscriptionState.success;
      notifyListeners();
    } catch (e) {
      state = SubscriptionState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _onPurchaseError(dynamic purchaseError) {
    state = SubscriptionState.error;
    errorMessage = purchaseError.toString();
    notifyListeners();
  }

  Future<void> checkExistingSubscription() async {
    try {
      final resultSubscription =
          await FlutterInappPurchase.instance.getAvailablePurchases();

      if (resultSubscription != null && resultSubscription.isNotEmpty) {
        final latestSubscription = resultSubscription.reduce(
          (current, next) =>
              (current.transactionDate?.millisecondsSinceEpoch ?? 0) >
                      (next.transactionDate?.millisecondsSinceEpoch ?? 0)
                  ? current
                  : next,
        );

        final data = jsonDecode(latestSubscription.transactionReceipt ?? '{}');
        final acknowledgedValue = data['acknowledged'] ?? false;

        UID.autoRenewing = data['autoRenewing'] ?? false;
        UID.purchaseToken = data['purchaseToken'] ?? '';
        UID.productId = data['productId'] ?? '';

        if (!acknowledgedValue) {
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
