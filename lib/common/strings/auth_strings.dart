import 'package:flutter/widgets.dart';

/// Textos da área de autenticação (login + cadastro) internacionalizados.
///
/// Resolve o idioma a partir da **localidade do dispositivo**
/// ([WidgetsBinding.instance.platformDispatcher.locale]) e devolve a string em
/// `pt` (Português) ou `en` (Inglês, fallback para qualquer outra localidade).
///
/// Uso: `AuthStrings.loginEmailHint`, `AuthStrings.signUpTitle`, etc. Todos os
/// getters são `static`, então podem ser usados tanto na View quanto no
/// ViewModel (que só precisa de `package:flutter/widgets.dart`). Nenhum texto
/// visível ao usuário fica solto como literal nas telas de auth — todos passam
/// por aqui, centralizando a tradução num arquivo só.
class AuthStrings {
  const AuthStrings._();

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

  // --- Login: rodapé ---
  static String get loginRegisterPrompt =>
      _isPt ? 'Quer se cadastrar? ' : 'No account yet? ';
  static String get loginRegisterAction => _isPt ? 'Clique aqui' : 'Sign up';

  // --- Login: erros (ViewModel) ---
  static String get loginErrorUserNotFound =>
      _isPt ? 'Usuário não encontrado.' : 'User not found.';
  static String get loginErrorWrongPassword =>
      _isPt ? 'Senha incorreta.' : 'Wrong password.';
  static String get loginErrorInvalidEmail =>
      _isPt ? 'E-mail inválido.' : 'Invalid email.';
  static String get loginErrorUserDisabled =>
      _isPt ? 'Usuário desativado.' : 'User disabled.';
  static String get loginErrorDefault =>
      _isPt
          ? 'Problemas para realizar seu login. Verifique sua senha e e-mail.'
          : 'Could not sign in. Please check your email and password.';

  // --- Cadastro: modal ---
  static String get signUpTitle => _isPt ? 'Criar uma conta' : 'Create account';
  static String get signUpButton => _isPt ? 'REGISTRAR' : 'SIGN UP';
  static String get signUpButtonLoading =>
      _isPt ? 'Registrando...' : 'Signing up...';

  // --- Cadastro: campos ---
  static String get signUpNameHint => _isPt ? 'SEU NOME' : 'YOUR NAME';
  static String get signUpEmailHint => _isPt ? 'E-MAIL' : 'EMAIL';
  static String get signUpPasswordHint => _isPt ? 'SENHA' : 'PASSWORD';

  // --- Cadastro: rodapé ---
  static String get signUpLoginPrompt =>
      _isPt ? 'Já tem uma conta? ' : 'Already have an account? ';
  static String get signUpLoginAction => _isPt ? 'Entre' : 'Sign in';

  // --- Cadastro: feedback / erros (ViewModel) ---
  static String get signUpSuccess =>
      _isPt ? 'Cadastro realizado com sucesso!' : 'Account created successfully!';
  static String get signUpErrorFillAll =>
      _isPt ? 'Por favor preencha todos os campos!' : 'Please fill in all fields!';
  static String get signUpErrorEmailInUse =>
      _isPt ? 'E-mail já cadastrado.' : 'Email already registered.';
  static String get signUpErrorInvalidEmail =>
      _isPt ? 'E-mail inválido.' : 'Invalid email.';
  static String get signUpErrorWeakPassword =>
      _isPt ? 'Senha muito fraca.' : 'Password is too weak.';
  static String get signUpErrorDisabled =>
      _isPt ? 'Cadastro desativado.' : 'Sign up disabled.';
  static String get signUpErrorDefault =>
      _isPt ? 'Problemas para registrar usuário!' : 'Could not register user!';

  // --- Comum (login + cadastro) ---
  static String get errorTitle => _isPt ? 'Erro!' : 'Error!';
}
