import 'package:flutter/widgets.dart';

/// Textos do módulo MainConfigMenu internacionalizados.
class MainConfigMenuStrings {
  const MainConfigMenuStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get pageTitle => _isPt ? 'Menu' : 'Menu';

  static String get menuPriceList =>
      _isPt ? 'Lista de preço' : 'Price list';

  static String get menuComments =>
      _isPt ? 'Meus comentários' : 'My comments';

  static String get premiumOnlyTitle =>
      _isPt ? 'Recurso premium' : 'Premium feature';

  static String get commentsPremiumOnly =>
      _isPt
          ? 'Salvar comentários com nome e texto melhorado por IA é exclusivo para assinantes.'
          : 'Saving comments with AI names and AI-improved text is for subscribers only.';

  static String get menuEditPdf =>
      _isPt ? 'Editar PDF' : 'Edit PDF';

  static String get menuChangeUsername =>
      _isPt ? 'Trocar nome de usuário' : 'Change username';

  static String get menuPremium =>
      _isPt ? 'Seja Premium (assinatura)' : 'Go Premium (subscription)';

  static String get menuDeleteAccount =>
      _isPt ? 'Excluir conta' : 'Delete account';
}
