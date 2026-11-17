import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:oflite/modules/core/in_app_purchase/data/datasource/in_app_purchase_remote_datasource.dart';
import 'package:oflite/modules/core/in_app_purchase/data/model/iap_purchase.dart';
import 'package:oflite/modules/core/in_app_purchase/data/repository/in_app_purchase_repository_impl.dart';

class FakeDataSource implements InAppPurchaseRemoteDataSource {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  QueryPurchaseDetailsResponse pastPurchases = QueryPurchaseDetailsResponse(
    pastPurchases: const [],
  );
  List<SK2Transaction> entitlements = const [];
  ProductDetailsResponse products = ProductDetailsResponse(
    productDetails: const [],
    notFoundIDs: const [],
  );
  PurchaseParam? lastParam;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase);

  @override
  Future<QueryPurchaseDetailsResponse> queryPastPurchasesAndroid() async =>
      pastPurchases;

  @override
  Future<List<SK2Transaction>> currentEntitlementsIos() async => entitlements;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      products;

  @override
  Future<bool> buyNonConsumable(PurchaseParam param) async {
    lastParam = param;
    return true;
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> restorePurchases() async {}
}

GooglePlayPurchaseDetails androidPurchase({
  bool isAutoRenewing = true,
  bool isAcknowledged = true,
  PurchaseStateWrapper state = PurchaseStateWrapper.purchased,
  int purchaseTime = 1000,
}) {
  return GooglePlayPurchaseDetails.fromPurchase(
    PurchaseWrapper(
      orderId: 'order',
      packageName: 'pkg',
      purchaseTime: purchaseTime,
      purchaseToken: 'android-token',
      signature: 'sig',
      products: const ['sku_android'],
      isAutoRenewing: isAutoRenewing,
      originalJson: '{}',
      isAcknowledged: isAcknowledged,
      purchaseState: state,
    ),
  ).single;
}

SK2PurchaseDetails iosPurchase(PurchaseStatus status, {String? expiration}) {
  return SK2PurchaseDetails(
    productID: 'sku_ios',
    purchaseID: status == PurchaseStatus.canceled ? null : '42',
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: 'jws',
      source: 'app_store',
    ),
    transactionDate: '2000',
    status: status,
    expirationDate: expiration,
  );
}

String _future() =>
    DateTime.now()
        .add(const Duration(days: 10))
        .millisecondsSinceEpoch
        .toString();
String _past() =>
    DateTime.now()
        .subtract(const Duration(days: 1))
        .millisecondsSinceEpoch
        .toString();

PricingPhaseWrapper phase(String price) => PricingPhaseWrapper(
  billingCycleCount: 1,
  billingPeriod: 'P1M',
  formattedPrice: price,
  priceAmountMicros: 0,
  priceCurrencyCode: 'BRL',
  recurrenceMode: RecurrenceMode.infiniteRecurring,
);

void main() {
  late FakeDataSource ds;

  setUp(() => ds = FakeDataSource());

  group('Android (assinantes existentes: mudança zero)', () {
    late InAppPurchaseRepositoryImpl repo;
    setUp(() => repo = InAppPurchaseRepositoryImpl(ds, isAndroid: true));

    test(
      'assinatura ativa mantém isAutoRenewing, token e data da Billing',
      () async {
        ds.pastPurchases = QueryPurchaseDetailsResponse(
          pastPurchases: [androidPurchase(purchaseTime: 123)],
        );
        final p = (await repo.getAvailablePurchases()).single;

        expect(p.isAutoRenewing, isTrue);
        expect(p.purchaseToken, 'android-token');
        expect(p.productId, 'sku_android');
        expect(p.transactionDate, 123);
        expect(p.needsCompletion, isFalse);
      },
    );

    test('renovação cancelada → isAutoRenewing false (igual hoje)', () async {
      ds.pastPurchases = QueryPurchaseDetailsResponse(
        pastPurchases: [androidPurchase(isAutoRenewing: false)],
      );
      expect(
        (await repo.getAvailablePurchases()).single.isAutoRenewing,
        isFalse,
      );
    });

    test('compra pendente nunca é premium', () {
      final p = repo.toPurchase(
        androidPurchase(state: PurchaseStateWrapper.pending),
      );
      expect(p.status, IapPurchaseStatus.pending);
      expect(p.isAutoRenewing, isFalse);
    });

    test('não reconhecida → needsCompletion e acknowledge completa', () async {
      final raw = androidPurchase(isAcknowledged: false);
      final p = repo.toPurchase(raw);
      expect(p.needsCompletion, isTrue);

      await repo.acknowledgePurchaseAndroid(p);
      expect(ds.completed, [raw]);
    });

    test('já reconhecida → acknowledge não chama a loja', () async {
      await repo.acknowledgePurchaseAndroid(repo.toPurchase(androidPurchase()));
      expect(ds.completed, isEmpty);
    });

    test('erro sem compras → lança (chamador grava false)', () {
      ds.pastPurchases = QueryPurchaseDetailsResponse(
        pastPurchases: const [],
        error: IAPError(source: 'google_play', code: 'x', message: 'falhou'),
      );
      expect(repo.getAvailablePurchases(), throwsStateError);
    });

    test('oferta índice 0 e preço da fase recorrente (não o trial)', () async {
      final wrapper = ProductDetailsWrapper(
        description: '',
        name: 'Premium',
        productId: 'sku_android',
        productType: ProductType.subs,
        title: 'Premium',
        subscriptionOfferDetails: [
          SubscriptionOfferDetailsWrapper(
            basePlanId: 'base',
            offerTags: const [],
            offerIdToken: 'token-0',
            pricingPhases: [phase('Grátis'), phase('R\$ 19,90')],
          ),
          SubscriptionOfferDetailsWrapper(
            basePlanId: 'base',
            offerTags: const [],
            offerIdToken: 'token-1',
            pricingPhases: [phase('R\$ 9,90')],
          ),
        ],
      );
      final details = GooglePlayProductDetails.fromProductDetails(wrapper);
      ds.products = ProductDetailsResponse(
        // Ordem invertida para garantir que a escolha é pelo índice.
        productDetails: details.reversed.toList(),
        notFoundIDs: const [],
      );

      final product = (await repo.fetchProducts(skus: ['sku_android'])).single;
      expect(product.displayPrice, 'R\$ 19,90');
      expect(product.offerTokenAndroid, 'token-0');

      await repo.requestSubscription('sku_android');
      expect(ds.lastParam, isA<GooglePlayPurchaseParam>());
      expect(
        (ds.lastParam!.productDetails as GooglePlayProductDetails).offerToken,
        'token-0',
      );
    });

    test('produto não encontrado → lista vazia', () async {
      expect(await repo.fetchProducts(skus: ['nao_existe']), isEmpty);
    });
  });

  group('iOS (regra nova: premium = vigente)', () {
    late InAppPurchaseRepositoryImpl repo;
    setUp(() => repo = InAppPurchaseRepositoryImpl(ds, isAndroid: false));

    test('restored → purchased (não cai em erro)', () {
      final p = repo.toPurchase(iosPurchase(PurchaseStatus.restored));
      expect(p.status, IapPurchaseStatus.purchased);
      expect(p.isAutoRenewing, isTrue);
      expect(p.purchaseToken, 'jws');
      expect(p.transactionDate, 2000);
    });

    test('expirada nunca é premium', () {
      final p = repo.toPurchase(
        iosPurchase(PurchaseStatus.purchased, expiration: _past()),
      );
      expect(p.isAutoRenewing, isFalse);
    });

    test('vigente (mesmo com renovação cancelada) é premium', () {
      final p = repo.toPurchase(
        iosPurchase(PurchaseStatus.purchased, expiration: _future()),
      );
      expect(p.isAutoRenewing, isTrue);
    });

    test('entitlements: vigente true, expirada false', () async {
      SK2Transaction t(String? exp) => SK2Transaction(
        id: '1',
        originalId: '1',
        productId: 'sku_ios',
        purchaseDate: '5000',
        expirationDate: exp,
        quantity: 1,
        appAccountToken: null,
        receiptData: 'jws',
      );
      ds.entitlements = [t(_future()), t(_past())];

      final result = await repo.getAvailablePurchases();
      expect(result.map((p) => p.isAutoRenewing), [true, false]);
      expect(result.first.transactionDate, 5000);
      expect(result.first.purchaseToken, 'jws');
    });

    test('finishTransaction completa compra comprada', () async {
      final raw = iosPurchase(PurchaseStatus.purchased);
      await repo.finishTransaction(repo.toPurchase(raw));
      expect(ds.completed, [raw]);
    });

    test('entitlement sem source → finish não chama a loja', () async {
      ds.entitlements = [
        SK2Transaction(
          id: '1',
          originalId: '1',
          productId: 'sku_ios',
          purchaseDate: '1',
          quantity: 1,
          appAccountToken: null,
        ),
      ];
      final p = (await repo.getAvailablePurchases()).single;
      await repo.finishTransaction(p);
      expect(ds.completed, isEmpty);
    });
  });

  group('streams', () {
    late InAppPurchaseRepositoryImpl repo;
    setUp(() => repo = InAppPurchaseRepositoryImpl(ds, isAndroid: false));

    test(
      'separa sucesso de erro/cancelado; restored vai para sucesso',
      () async {
        final updated = <IapPurchase>[];
        final errors = <IapPurchase>[];
        repo.purchaseUpdatedStream.listen(updated.add);
        repo.purchaseErrorStream.listen(errors.add);

        ds.controller.add([
          iosPurchase(PurchaseStatus.restored),
          iosPurchase(PurchaseStatus.pending),
          iosPurchase(PurchaseStatus.canceled),
          iosPurchase(PurchaseStatus.error),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(updated.map((p) => p.status), [
          IapPurchaseStatus.purchased,
          IapPurchaseStatus.pending,
        ]);
        expect(errors.map((p) => p.status), [
          IapPurchaseStatus.cancelled,
          IapPurchaseStatus.error,
        ]);
      },
    );

    test('erro Android não reconhecido é completado automaticamente', () async {
      final androidRepo = InAppPurchaseRepositoryImpl(ds, isAndroid: true);
      androidRepo.purchaseErrorStream.listen((_) {});

      final raw = androidPurchase(
        isAcknowledged: false,
        state: PurchaseStateWrapper.unspecified_state,
      );
      ds.controller.add([raw]);
      await Future<void>.delayed(Duration.zero);

      expect(ds.completed, [raw]);
    });
  });
}
