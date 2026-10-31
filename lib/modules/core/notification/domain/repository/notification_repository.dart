import 'package:flutter/material.dart';

/// Contrato para gerenciamento de notificações push (FCM + local).
///
/// Responsabilidades:
/// - Inicializar plugins de notificação local.
/// - Configurar handlers FCM (foreground, background, terminated).
/// - Gerenciar token FCM e persisti-lo no Firestore.
/// - Deep-link para orçamento via toque no banner.
abstract class NotificationRepository {
  /// Inicializa tudo (plugins, canais, handlers, permissões, token).
  Future<void> initialize();

  /// Token FCM atual (em memória volátil).
  Future<String?> currentToken();

  /// Recebe a chave global do navigator e tenta abrir orçamento pendente.
  void setNavigatorKey(GlobalKey<NavigatorState> key);

  /// Tenta abrir um orçamento pendente (cold-start pelo banner).
  void tryOpenPendingBudget();

  /// Chamado após login do dono. Persiste token FCM e inicia listeners.
  void startBudgetApprovalListener(String ownerUid);

  /// Encerra vínculos (ex.: logout).
  void stopBudgetApprovalListener();

  /// Carrega lista de tokens FCM cadastrados para o dono.
  Future<List<String>> loadFcmTokens(String ownerUid);

  /// Persiste o token FCM atual do dono no Firestore (chamada explícita).
  Future<void> persistCurrentTokenToFirebase(String ownerUid);
}
