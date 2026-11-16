import 'package:flutter/widgets.dart';

/// Strings da página pública de suporte (pt/en pelo Locale do navegador).
class SupportPtString {
  SupportPtString._();

  static bool get _isPt =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'pt';

  static String get pageTitle => _isPt ? 'Suporte' : 'Support';

  static String get appName => 'Orçamentos de vendas - PDF';

  static String get description =>
      _isPt
          ? 'Precisa de ajuda com o app? Fale com a gente pelo WhatsApp.'
          : 'Need help with the app? Talk to us on WhatsApp.';

  static String get button => _isPt ? 'Falar com suporte' : 'Contact support';

  static String get whatsappMessage =>
      _isPt
          ? 'Olá! Preciso de ajuda com o app Orçamentos de vendas - PDF.'
          : 'Hi! I need help with the Orçamentos de vendas - PDF app.';
}
