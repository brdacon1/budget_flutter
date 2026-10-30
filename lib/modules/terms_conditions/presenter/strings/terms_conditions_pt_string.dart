import 'package:flutter/widgets.dart';

/// Textos do módulo TermsConditions internacionalizados.
class TermsConditionsStrings {
  const TermsConditionsStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get pageTitle =>
      _isPt ? 'Política de privacidade' : 'Privacy Policy';

  static String get errorLoadPage => _isPt
      ? 'Não foi possível carregar a página. Verifique sua conexão com a internet.'
      : 'Could not load the page. Please check your internet connection.';

  static String get errorFallback =>
      _isPt ? 'Erro ao carregar a página.' : 'Error loading the page.';

  static String get retryButton =>
      _isPt ? 'Tentar novamente' : 'Try again';
}
