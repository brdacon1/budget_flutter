import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/in_app_purchase/data/model/iap_product.dart';
import 'package:oflite/modules/core/in_app_purchase/data/model/iap_purchase.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'package:oflite/shared/common/constants/environment.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/subscription/presenter/strings/subscription_pt_string.dart';

enum SubscriptionState { idle, loading, success, cancelled, error }

class SubscriptionViewModel extends ChangeNotifier {
  final InAppPurchaseRepository _iap;

  SubscriptionViewModel({InAppPurchaseRepository? iapRepository})
    : _iap = iapRepository ?? getIt<InAppPurchaseRepository>();

  SubscriptionState state = SubscriptionState.idle;

  bool _disposed = false;

  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;

  // SKU por plataforma, lido dos arquivos de ambiente
  String get _androidSku => Environment.instance.subscription.androidSku;
  String get _iosSku => Environment.instance.subscription.iosSku;

  String get sku => Platform.isAndroid ? _androidSku : _iosSku;

  /// Guarda os produtos buscados (para obter offerToken no Android)
  List<IapProduct> _availableProducts = [];

  List<IapProduct> get availableProducts => _availableProducts;

  bool get hasProducts => _availableProducts.isNotEmpty;

  String? get displayPrice =>
      _availableProducts.isNotEmpty
          ? _availableProducts.first.displayPrice
          : null;

  Future<void> init() async {
    state = SubscriptionState.idle;
    _safeNotify();

    try {
      await _iap.initConnection();

      final products = await _iap.fetchProducts(skus: [sku]);

      _availableProducts = products;

      if (kDebugMode) {
        print('[SubscriptionViewModel] Produtos: ${products.length}');
        for (final p in products) {
          print(
            '  • ${p.id} - ${p.displayPrice} token: ${p.offerTokenAndroid}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('[SubscriptionViewModel] Erro init: $e');
      // Não quebra o flow para não travar a UI no emulador
    }

    if (_disposed) return;
    _safeNotify();

    _purchaseUpdatedSubscription = _iap.purchaseUpdatedStream.listen(
      _onPurchaseUpdated,
    );
    _purchaseErrorSubscription = _iap.purchaseErrorStream.listen(
      _onPurchaseError,
    );
  }

  Future<void> requestSubscription() async {
    if (_disposed) return;

    state = SubscriptionState.loading;
    _safeNotify();

    try {
      // Android precisa do offerToken do produto buscado
      String? offerToken;
      if (Platform.isAndroid) {
        final product = _availableProducts.cast<IapProduct?>().firstWhere(
          (p) => p?.id == sku,
          orElse: () => null,
        );

        offerToken = product?.offerTokenAndroid;

        if (offerToken == null) {
          throw Exception(SubscriptionStrings.offerTokenError(sku));
        }
      }

      await _iap.requestSubscription(sku);
      // Sucesso/erro vem pelo listener
    } catch (e) {
      if (_disposed) return;
      _fail(e);
    }
  }

  void _onPurchaseUpdated(IapPurchase purchase) async {
    if (_disposed) return;

    try {
      _updateSubscriptionSession(
        autoRenewing: purchase.isAutoRenewing,
        purchaseToken: purchase.purchaseToken,
        productId: purchase.productId,
      );

      if (purchase.status == IapPurchaseStatus.purchased) {
        // Android: acknowledge obrigatório em até 3 dias
        if (Platform.isAndroid && purchase.needsCompletion) {
          await _iap.acknowledgePurchaseAndroid(purchase);
        }

        // iOS: FINALIZAR TRANSAÇÃO é obrigatório!
        if (Platform.isIOS) {
          await _iap.finishTransaction(purchase);
        }

        if (_disposed) return;
        state = SubscriptionState.success;
      } else if (purchase.status == IapPurchaseStatus.pending) {
        state = SubscriptionState.success;
      } else {
        state = SubscriptionState.error;
      }
      _safeNotify();
    } catch (e) {
      if (_disposed) return;
      _fail(e);
    }
  }

  void _onPurchaseError(IapPurchase purchaseError) {
    if (_disposed) return;

    _fail(purchaseError);
  }

  /// Nunca expõe o erro cru da loja para a UI: só o estado.
  void _fail(Object e) {
    if (kDebugMode) print('[SubscriptionViewModel] Erro: $e');
    state =
        e is IapPurchase && e.status == IapPurchaseStatus.cancelled
            ? SubscriptionState.cancelled
            : SubscriptionState.error;
    _safeNotify();
  }

  /// Restaura compras anteriores (obrigatório ter na App Store)
  Future<void> restorePurchases() async {
    if (_disposed) return;

    state = SubscriptionState.loading;
    _safeNotify();

    try {
      // iOS: restorePurchases dispara as transações pelo listener
      await _iap.restorePurchases();
      // O resultado vem pelo _purchaseUpdatedListener
    } catch (e) {
      if (_disposed) return;
      _fail(e);
    }
  }

  Future<void> checkExistingSubscription() async {
    if (_disposed) return;

    try {
      final result = await _iap.getAvailablePurchases();

      if (result.isNotEmpty) {
        final latest = result.reduce(
          (current, next) =>
              current.transactionDate > next.transactionDate ? current : next,
        );

        _updateSubscriptionSession(
          autoRenewing: latest.isAutoRenewing,
          purchaseToken: latest.purchaseToken,
          productId: latest.productId,
        );

        if (Platform.isAndroid && latest.needsCompletion) {
          await _iap.acknowledgePurchaseAndroid(latest);
        }
      } else {
        _updateSubscriptionSession(autoRenewing: false, purchaseToken: '');
      }
    } catch (e) {
      _updateSubscriptionSession(autoRenewing: false, purchaseToken: '');
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
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
    // Força notificação porque InfoUser é mutável e ValueNotifier não
    // dispara listeners quando o mesmo objeto é reassinalado.
    getIt<UserRepository>().selectUser.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }
}
