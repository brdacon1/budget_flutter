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

  static String get menuEditPdf =>
      _isPt ? 'Editar PDF' : 'Edit PDF';

  static String get menuChangeUsername =>
      _isPt ? 'Trocar nome de usuário' : 'Change username';
}
