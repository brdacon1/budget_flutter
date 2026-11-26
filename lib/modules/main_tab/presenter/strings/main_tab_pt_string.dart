import 'package:flutter/widgets.dart';

/// Textos do módulo MainTab internacionalizados.
class MainTabStrings {
  const MainTabStrings._();

  static bool get _isPt =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'pt';

  static String get editLogoTitle => _isPt ? 'Editar Logo' : 'Edit Logo';

  /// Faixa do teste grátis. [hours] = horas restantes (arredondado p/ cima).
  static String trialBanner(int hours) {
    if (hours >= 24) {
      final days = (hours / 24).ceil();
      return _isPt
          ? 'Teste grátis: faltam $days dia${days > 1 ? 's' : ''} • Assinar'
          : 'Free trial: $days day${days > 1 ? 's' : ''} left • Subscribe';
    }
    return _isPt
        ? 'Teste grátis: faltam ${hours}h • Assinar'
        : 'Free trial: ${hours}h left • Subscribe';
  }
}
