import 'package:flutter/widgets.dart';

/// Strings visíveis ao usuário da página pública de exclusão de conta.
///
/// Segue o padrão do módulo web_budget: internacionalização simples
/// via Locale do dispositivo/navegador com getters estáticos.
class DeleteAccountPtString {
  DeleteAccountPtString._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static bool get _isPt => _locale.languageCode == 'pt';

  // Títulos e headings
  static String get pageTitle =>
      _isPt ? 'Excluir conta e dados' : 'Delete account and data';

  static String get appName => 'Orçamentos de vendas - PDF';

  static String get subTitle =>
      _isPt
          ? 'Solicite a exclusão completa da sua conta e de todos os dados pessoais associados.'
          : 'Request the complete deletion of your account and all associated personal data.';

  // Instruções / etapas
  static String get stepsTitle =>
      _isPt ? 'Como solicitar a exclusão' : 'How to request deletion';

  static String get step1 =>
      _isPt
          ? 'Digite abaixo o e-mail cadastrado na sua conta OfLite.'
          : 'Enter the email registered to your OfLite account below.';

  static String get step2 =>
      _isPt
          ? 'Marque a caixa de confirmação para confirmar que deseja excluir tudo.'
          : 'Check the confirmation box to confirm you want to delete everything.';

  static String get step3 =>
      _isPt
          ? 'Clique em "Excluir conta e dados". A remoção é imediata e irreversível.'
          : 'Click "Delete account and data". Removal is immediate and irreversible.';

  // Dados excluídos / mantidos
  static String get dataTitle =>
      _isPt ? 'Quais dados são excluídos?' : 'What data is deleted?';

  static String get dataDeletedIntro =>
      _isPt
          ? 'Ao confirmar, removemos permanentemente:'
          : 'Upon confirmation, we permanently remove:';

  static String get dataDeleted1 =>
      _isPt
          ? 'Dados de perfil (nome, telefone, e-mail)'
          : 'Profile data (name, phone, email)';

  static String get dataDeleted2 =>
      _isPt
          ? 'Dados da empresa (CNPJ, endereço, logo)'
          : 'Company data (tax ID, address, logo)';

  static String get dataDeleted3 =>
      _isPt
          ? 'Orçamentos, itens, comentários e observações'
          : 'Budgets, items, comments and observations';

  static String get dataDeleted4 =>
      _isPt
          ? 'Recibos, pagamentos e histórico financeiro'
          : 'Receipts, payments and financial history';

  static String get dataDeleted5 =>
      _isPt
          ? 'Tokens de notificação push e alertas'
          : 'Push notification tokens and alerts';

  static String get dataRetainedTitle =>
      _isPt ? 'Dados mantidos temporariamente' : 'Temporarily retained data';

  static String get dataRetained =>
      _isPt
          ? 'Backups automáticos criptografados do Firebase podem reter cópias anonimizadas por até 30 dias para fins de segurança e auditoria, após o que são excluídos permanentemente.'
          : 'Encrypted Firebase automatic backups may retain anonymized copies for up to 30 days for security and audit purposes, after which they are permanently deleted.';

  // Formulário
  static String get emailLabel => _isPt ? 'E-mail' : 'Email';

  static String get emailHint =>
      _isPt ? 'seu-email@exemplo.com' : 'your-email@example.com';

  static String get emailRequired =>
      _isPt
          ? 'Informe o e-mail cadastrado.'
          : 'Please enter your registered email.';

  static String get emailInvalid =>
      _isPt ? 'Informe um e-mail válido.' : 'Please enter a valid email.';

  static String get confirmLabel =>
      _isPt
          ? 'Entendo que esta ação é irreversível e desejo excluir minha conta e todos os meus dados.'
          : 'I understand this action is irreversible and want to delete my account and all my data.';

  static String get confirmRequired =>
      _isPt
          ? 'Você precisa confirmar para prosseguir.'
          : 'You must confirm to proceed.';

  static String get deleteButton =>
      _isPt ? 'Excluir conta e dados' : 'Delete account and data';

  static String get deleting => _isPt ? 'Excluindo...' : 'Deleting...';

  // Resultados
  static String get successTitle =>
      _isPt ? 'Conta excluída' : 'Account deleted';

  static String get successMessage =>
      _isPt
          ? 'Sua conta e todos os seus dados foram removidos com sucesso.'
          : 'Your account and all your data have been successfully removed.';

  static String get errorTitle => _isPt ? 'Erro ao excluir' : 'Deletion error';

  static String get errorGeneric =>
      _isPt
          ? 'Não foi possível processar a exclusão. Tente novamente mais tarde.'
          : 'Could not process the deletion. Please try again later.';

  static String get errorNotFound =>
      _isPt
          ? 'Nenhuma conta encontrada com este e-mail.'
          : 'No account found with this email.';
}
