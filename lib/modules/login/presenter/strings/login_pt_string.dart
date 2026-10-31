import 'package:flutter/widgets.dart';

/// Textos do módulo Login internacionalizados.
///
/// Resolve o idioma a partir da **localidade do dispositivo**
/// ([WidgetsBinding.instance.platformDispatcher.locale]) e devolve a string em
/// `pt` (Português) ou `en` (Inglês, fallback para qualquer outra localidade).
///
/// Uso: `LoginStrings.loginEmailHint`, `LoginStrings.loginTitle`, etc. Todos os
/// getters são `static`, então podem ser usados tanto na View quanto no
/// ViewModel (que só precisa de `package:flutter/widgets.dart`). Nenhum texto
/// visível ao usuário fica solto como literal nas telas de login — todos passam
/// por aqui, centralizando a tradução num arquivo só.
class LoginStrings {
  const LoginStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  // --- Login: header / campos ---
  static String get loginTitle => _isPt ? 'Entrar' : 'Sign in';
  static String get loginEmailHint => _isPt ? 'E-mail' : 'Email';
  static String get loginPasswordHint => _isPt ? 'Senha' : 'Password';

  // --- Login: botões ---
  static String get loginButton => _isPt ? 'Entrar' : 'Sign in';
  static String get loginForgotPassword =>
      _isPt ? 'Esqueceu sua senha?' : 'Forgot your password?';
  static String get loginWithGoogle =>
      _isPt ? 'Login com Google' : 'Sign in with Google';
  static String get loginPrivacyPolicy =>
      _isPt ? 'Política de privacidade' : 'Privacy policy';

  // --- Login: botão de cadastro em destaque ---
  static String get loginRegisterButton => _isPt ? 'Cadastrar' : 'Sign up';

  // --- Login: rodapé ---
  static String get loginRegisterPrompt =>
      _isPt ? 'Quer se cadastrar? ' : 'No account yet? ';
  static String get loginRegisterAction =>
      _isPt ? 'Clique aqui' : 'Sign up';

  // --- Login: erros (ViewModel) ---
  static String get loginErrorUserNotFound =>
      _isPt ? 'Usuário não encontrado.' : 'User not found.';
  static String get loginErrorWrongPassword =>
      _isPt ? 'Senha incorreta.' : 'Wrong password.';
  static String get loginErrorInvalidEmail =>
      _isPt ? 'E-mail inválido.' : 'Invalid email.';
  static String get loginErrorUserDisabled =>
      _isPt ? 'Usuário desativado.' : 'User disabled.';
  static String get loginErrorDefault => _isPt
      ? 'Problemas para realizar seu login. Verifique sua senha e e-mail.'
      : 'Could not sign in. Please check your email and password.';

  // --- Comum (login + outras telas de auth) ---
  static String get errorTitle => _isPt ? 'Erro!' : 'Error!';
}
