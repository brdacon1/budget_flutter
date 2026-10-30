import 'package:flutter/material.dart';

/// Contrato para exibição de alertas (snackbars) e modais (bottom sheets).
///
/// Esta interface mantém a assinatura pública que as ViewModels já
/// consomem, permitindo troca por mock em testes unitários.
abstract class DisplayAlertRepository {
  /// Alerta de erro (snackbar vermelho).
  Future<void> notificationError(
    BuildContext context,
    String firstMessage,
    String secondMessage,
  );

  /// Alerta de aviso (snackbar laranja).
  Future<void> notificationWarning(
    BuildContext context,
    String firstMessage,
    String secondMessage,
  );

  /// Alerta de sucesso (snackbar verde) — não fecha a tela atual.
  Future<void> notificationNotCloseScreen(
    BuildContext context,
    String firstMessage,
    String secondMessage,
  );

  /// Alerta de sucesso (snackbar verde).
  Future<void> notification(
    BuildContext context,
    String firstMessage,
    String secondMessage,
  );

  /// Modal de recuperação de senha (bottom sheet com campo de e-mail).
  Future<void> dialogChangePassword(BuildContext context);

  /// Modal para trocar o nome do usuário (bottom sheet com campo de nome).
  Future<void> dialogChangeName(BuildContext context);

  /// Modal de opções para adicionar orçamento (anúncio x premium).
  ///
  /// Retorna o valor selecionado (string vazia se usuário cancelar).
  Future<String> adsNotification(BuildContext context);

  /// Modal de opções para inserir item (criar novo x selecionar da lista).
  ///
  /// Retorna o valor selecionado (string vazia se usuário cancelar).
  Future<String> listNotification(BuildContext context);
}
