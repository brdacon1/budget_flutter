import 'package:flutter/widgets.dart';

/// Textos do módulo SingUp (cadastro) internacionalizados.
///
/// Resolve o idioma a partir da **localidade do dispositivo**
/// ([WidgetsBinding.instance.platformDispatcher.locale]) e devolve a string em
/// `pt` (Português) ou `en` (Inglês, fallback para qualquer outra localidade).
///
/// Uso: `SingUpStrings.signUpTitle`, `SingUpStrings.signUpButton`, etc. Todos os
/// getters são `static`, então podem ser usados tanto na View quanto no
/// ViewModel (que só precisa de `package:flutter/widgets.dart`). Nenhum texto
/// visível ao usuário fica solto como literal nas telas de cadastro — todos passam
/// por aqui, centralizando a tradução num arquivo só.
class SingUpStrings {
  const SingUpStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  // --- Cadastro: modal ---
  static String get signUpTitle =>
      _isPt ? 'Criar uma conta' : 'Create account';
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
  static String get signUpLoginAction =>
      _isPt ? 'Entre' : 'Sign in';

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
}
