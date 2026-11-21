import 'package:flutter/widgets.dart';

/// Textos da tela de exclusão de conta dentro do app.
class DeleteAccountInAppStrings {
  const DeleteAccountInAppStrings._();

  static bool get _isPt =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'pt';

  static String get title => _isPt ? 'Excluir conta' : 'Delete account';

  static String get warning => _isPt
      ? 'Esta ação é permanente. Sua conta, orçamentos, produtos, clientes e '
            'demais dados serão apagados e não poderão ser recuperados.'
      : 'This action is permanent. Your account, budgets, products, clients '
            'and all other data will be deleted and cannot be recovered.';

  static String get subscriptionNote => _isPt
      ? 'Se você tiver uma assinatura ativa, cancele-a nas configurações da '
            'loja (App Store / Google Play) para não ser cobrado novamente.'
      : 'If you have an active subscription, cancel it in your store settings '
            '(App Store / Google Play) to avoid being charged again.';

  static String get reauthNote => _isPt
      ? 'Por segurança, vamos pedir que você confirme seu login.'
      : 'For security, you will be asked to confirm your sign-in.';

  static String get passwordLabel => _isPt ? 'Senha da conta' : 'Account password';

  static String get confirmLabel => _isPt
      ? 'Entendo que todos os meus dados serão excluídos permanentemente.'
      : 'I understand all my data will be permanently deleted.';

  static String get button => _isPt ? 'Excluir minha conta' : 'Delete my account';

  static String get errorPassword =>
      _isPt ? 'Informe a senha da conta.' : 'Enter your account password.';

  static String get errorConfirm => _isPt
      ? 'Você precisa confirmar para prosseguir.'
      : 'You must confirm to continue.';

  static String get errorInvalidCredentials =>
      _isPt ? 'Senha incorreta.' : 'Incorrect password.';

  static String get errorTitle =>
      _isPt ? 'Não foi possível excluir' : 'Could not delete account';

  static String get errorMessage => _isPt
      ? 'Verifique sua conexão e tente novamente.'
      : 'Check your connection and try again.';

  static String get successTitle => _isPt ? 'Conta excluída' : 'Account deleted';

  static String get successMessage => _isPt
      ? 'Sua conta e seus dados foram removidos.'
      : 'Your account and data have been removed.';
}
