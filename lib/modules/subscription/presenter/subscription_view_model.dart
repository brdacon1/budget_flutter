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
import 'package:oflite/modules/subscription/data/model/subscription_plan.dart';
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

  /// Plano marcado na tela (o anual vem pré-selecionado; se a loja não
  /// devolver o anual, [init] volta para o mensal).
  SubscriptionPlan selectedPlan = SubscriptionPlan.yearly;

  /// SKU de cada plano por plataforma, lido dos arquivos de ambiente.
  String skuFor(SubscriptionPlan plan) {
    final config = Environment.instance.subscription;
    return switch (plan) {
      SubscriptionPlan.monthly =>
        Platform.isAndroid ? config.androidSku : config.iosSku,
      SubscriptionPlan.yearly =>
        Platform.isAndroid ? config.androidYearSku : config.iosYearSku,
    };
  }

  /// SKU do plano selecionado.
  String get sku => skuFor(selectedPlan);

  /// Guarda os produtos buscados (para obter offerToken no Android)
  List<IapProduct> _availableProducts = [];

  List<IapProduct> get availableProducts => _availableProducts;

  bool get hasProducts => _availableProducts.isNotEmpty;

  /// Preço recorrente do [plan] formatado pela loja; `null` enquanto carrega
  /// ou se o plano não existe na loja.
  String? priceFor(SubscriptionPlan plan) {
    final id = skuFor(plan);
    for (final p in _availableProducts) {
      if (p.id == id) return p.displayPrice;
    }
    return null;
  }

  /// O plano só aparece na tela se a loja devolveu o produto.
  bool hasPlan(SubscriptionPlan plan) => priceFor(plan) != null;

  String? get displayPrice => priceFor(selectedPlan);

  /// `true` enquanto os produtos ainda estão sendo buscados na loja.
  bool isLoadingProducts = true;

  void selectPlan(SubscriptionPlan plan) {
    if (_disposed || plan == selectedPlan || !hasPlan(plan)) return;
    selectedPlan = plan;
    _safeNotify();
  }

  Future<void> init() async {
    state = SubscriptionState.idle;
    _safeNotify();

    try {
      await _iap.initConnection();

      final products = await _iap.fetchProducts(
        skus: [
          skuFor(SubscriptionPlan.monthly),
          skuFor(SubscriptionPlan.yearly),
        ],
      );

      _availableProducts = products;

      // Anual indisponível na loja → cai para o mensal (comportamento antigo).
      if (!hasPlan(selectedPlan) && hasPlan(SubscriptionPlan.monthly)) {
        selectedPlan = SubscriptionPlan.monthly;
      }

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

    isLoadingProducts = false;
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
