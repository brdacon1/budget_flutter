import 'package:flutter/widgets.dart';

/// Textos do módulo Subscription internacionalizados.
class SubscriptionStrings {
  const SubscriptionStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get pageTitle => _isPt ? 'Premium' : 'Premium';

  static String get benefitsTitle =>
      _isPt ? 'Benefícios' : 'Benefits';

  static String get expandLess => _isPt ? 'menos' : 'less';

  static String get expandMore => _isPt ? 'mais..' : 'more..';

  static String get priceTitle => _isPt ? 'Preço' : 'Price';

  static String get defaultPrice => _isPt ? 'R\$ 3,59/mês' : r'$ 3.59/month';

  static String get subscribeButton =>
      _isPt ? 'ASSINAR' : 'SUBSCRIBE';

  static String get restoreButton =>
      _isPt ? 'Restaurar Compras' : 'Restore Purchases';

  static String get subscriptionNotCompleted =>
      _isPt ? 'Assinatura não realizada' : 'Subscription not completed';

  static String offerTokenError(String sku) => _isPt
      ? 'Offer token não encontrado. Verifique se o produto "$sku" está configurado com base plan na Play Console.'
      : 'Offer token not found. Please check if product "$sku" is configured with base plan in the Play Console.';

  static String get ratingTitle =>
      _isPt ? 'Avaliações' : 'Reviews';

  static String get ratingValue => '5.0';

  static String get bestPrice =>
      _isPt ? 'Melhor preço' : 'Best price';
}
