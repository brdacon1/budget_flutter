import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/global_uid_budget.dart' as budget;
import 'package:oflite/models/global_uid_user.dart' as uid;
import 'package:oflite/presentations/budget/budget_tab/budget_tab_view.dart';
import 'package:oflite/services/http_request.dart';

/// Inicializa e gerencia as notificações push (FCM) do app.
///
/// Responsabilidades:
/// - Inicializa o `flutter_local_notifications` e cria o canal Android
///   `high_importance_channel` em runtime (obrigatório no Android 8+ para que
///   FCM consiga exibir notificações que referenciem esse canal).
/// - Configura a apresentação de notificações em foreground (iOS).
/// - Registra um listener `FirebaseMessaging.onMessage` que mostra a
///   notificação localmente quando o app está aberto (no Android, FCM **não**
///   exibe notificações em foreground sozinho — é preciso este listener).
/// - Solicita permissão e recupera o token FCM do dispositivo.
///
/// O token atualmente é apenas logado em debug. Se o backend precisar enviar
/// push por dispositivo, envie `token` para a sua API aqui.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Chave do navigator global do app (definida em `main.dart`). Usada para
  /// navegar até o orçamento quando o dono **toca no banner** da notificação
  // de aprovação/reprovação vinda do fluxo Web.
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Id do orçamento pendente de abertura: preenchido quando o toque na
  // notificação chega antes do navigator estar pronto (ex.: cold-start do
  // app pelo toque). Processado assim que [setNavigatorKey] é chamado.
  String? _pendingBudgetId;

  // Listener em tempo real das notificações de aprovação/reprovação de
  // orçamento que chegam pelo fluxo Web (escrita em
  // `EMPRESAS/{uid}/USERS/{uid}/NOTIFICACOES`). Ver [startBudgetApprovalListener].
  StreamSubscription<QuerySnapshot>? _budgetApprovalSub;

  /// Inicializa tudo. Deve ser chamado após `Firebase.initializeApp()`.
  Future<void> initialize() async {
    // 1) Inicializa o plugin de notificações locais (Android usa o ícone do app).
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    // O callback `onDidReceiveNotificationResponse` dispara quando o usuário
    // **toca** numa notificação local enquanto o app está em foreground ou é
    // retomado da background. É aqui que abrimos o orçamento aprovado/
    // reprovado a partir do payload (`ORCAMENTO_ID`) gravado no `.show()`.
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Cold-start: se o app foi aberto pelo toque numa notificação, o payload
    // não passa pelo `onDidReceiveNotificationResponse` — é preciso ler os
    // launch details. Aguardamos aqui (chamada nativa rápida) para garantir
    // que `_pendingBudgetId` esteja preenchido antes de `setNavigatorKey`/
    // `MainTabView` tentarem consumi-lo.
    await _handleLaunchNotification();

    // 2) Cria o canal de alta importância em runtime (Android 8+ exige canal).
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
        ));

    // 3) iOS: permite que FCM mostre alert/badge/som em foreground.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4) Listener de mensagens em foreground. No Android é a única forma de
    //    exibir notificações com `notification` payload enquanto o app está
    //    aberto.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5) Permissão + token.
    await FirebaseMessaging.instance.requestPermission();
    final String? token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      debugPrint('FCM token: $token');
      // TODO: enviar `token` para o backend se a API envia push por dispositivo.
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Toque no banner da notificação -> abre o orçamento aprovado/reprovado
  // ---------------------------------------------------------------------------

  /// Recebe a chave global do navigator (de `main.dart`) e, se houver um
  /// orçamento pendente (toque que chegou antes do navigator estar pronto),
  /// tenta abrir agora. Idempotente.
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    tryOpenPendingBudget();
  }

  /// Tenta abrir um orçamento pendente (cold-start pelo toque na notificação
  /// antes do navigator/dono estarem prontos). Deve ser chamado em momentos
  /// seguros: após o login (quando `uid.user` está disponível) e/ou quando a
  /// tela principal (`MainTabView`) é construída. Idempotente.
  void tryOpenPendingBudget() {
    final pending = _pendingBudgetId;
    if (pending == null || pending.isEmpty) return;
    final key = _navigatorKey;
    if (key == null || key.currentContext == null) return;
    final owner = uid.user;
    if (owner == null || owner.isEmpty) return;
    _pendingBudgetId = null;
    unawaited(_openBudget(pending));
  }

  void _onNotificationTap(NotificationResponse response) {
    final budgetId = response.payload;
    if (budgetId == null || budgetId.isEmpty) return;
    unawaited(_openBudget(budgetId));
  }

  /// Cold-start: o app foi aberto pelo toque numa notificação local. O
  /// `onDidReceiveNotificationResponse` não dispara nesse caso, então lemos
  /// os launch details do plugin. Se o payload for um id de orçamento,
  /// abrimos ele (depois que o navigator estiver pronto).
  Future<void> _handleLaunchNotification() async {
    if (kIsWeb) return;
    final details =
        await _localNotifications.getNotificationAppLaunchDetails();
    final payload = details?.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) {
      _pendingBudgetId = payload;
    }
  }

  /// Abre o orçamento [budgetId] (mesmo id gravado em `ORCAMENTO_ID` no
  /// documento de notificação) na tela `BudgetTabView`, reutilizando o
  /// `HttpRequest.getInformationOrcamento1` do app mobile — nenhuma regra
  /// paralela. Se o navigator ainda não estiver pronto, guarda como pendente.
  Future<void> _openBudget(String budgetId) async {
    final key = _navigatorKey;
    if (key == null || key.currentContext == null) {
      _pendingBudgetId = budgetId;
      return;
    }
    // Só faz sentido abrir se o dono está logado (caso contrário o listener
    // nem estaria ativo e não haveria notificação para tocar).
    final owner = uid.user;
    if (owner == null || owner.isEmpty) {
      _pendingBudgetId = budgetId;
      return;
    }
    try {
      budget.IDORCAMENTO = budgetId;
      final customer = await HttpRequest().getInformationOrcamento1();
      customer.id ??= budgetId;
      final context = key.currentContext!;
      if (!context.mounted) {
        _pendingBudgetId = budgetId;
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BudgetTabView(item: customer)),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('open budget from notification failed: $e');
      // Em falha de leitura, mesmo assim tenta abrir com id preenchido para
      // o dono não ficar sem resposta ao toque.
      final context = key.currentContext;
      if (context != null && context.mounted) {
        final fallback = CustomerInfo()..id = budgetId;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BudgetTabView(item: fallback)),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Notificações de aprovação/reprovação vindas do fluxo Web
  // ---------------------------------------------------------------------------
  //
  // Quando o cliente aprova/reprova um orçamento pela Web, o fluxo Web grava
  // um documento em `EMPRESAS/{uid}/USERS/{uid}/NOTIFICACOES` (mesmo path já
  // usado pelo app, mesmo dono). Aqui o app do dono escuta essa coleção em
  // tempo real e dispara uma **notificação local** (push visual no aparelho)
  // avisando que o cliente aprovou/reprovou o orçamento. O payload da
  // notificação local é o `ORCAMENTO_ID`, usado para abrir o orçamento quando
  // o dono toca no banner.
  //
  // É **aditivo**: só acrescenta a escuta; não muda regras de negócio nem o
  // comportamento das telas mobile existentes. O último timestamp visto é
  // guardado em SharedPreferences, então aprovações que chegaram enquanto o
  // app estava fechado também geram um aviso ao reabrir (catch-up).

  static const String _lastSeenKey = 'budget_web_notif_last_seen';

  /// Inicia a escuta de notificações de aprovação para o dono [ownerUid].
  /// Deve ser chamado depois que o dono faz login (quando `global_uid_user.user`
  // fica disponível). Idempotente: chamar de novo só troca o dono.
  void startBudgetApprovalListener(String ownerUid) {
    // Não roda no Web público (lá só há o fluxo do cliente, não o do dono).
    if (kIsWeb) return;
    _budgetApprovalSub?.cancel();
    _budgetApprovalSub = FirebaseFirestore.instance
        .collection('EMPRESAS/$ownerUid/USERS/$ownerUid/NOTIFICACOES')
        .orderBy('CRIADO_EM', descending: true)
        .limit(20)
        .snapshots()
        .listen(_onBudgetApprovalSnapshot, onError: (Object e) {
      if (kDebugMode) debugPrint('budget approval listener error: $e');
    });

    // Best-effort: guarda o token FCM atual do dono no próprio path, para um
    // futuro backend/Cloud Function poder enviar push real por dispositivo.
    unawaited(_persistFcmToken(ownerUid));
  }

  /// Encerra a escuta (ex.: logout). Idempotente.
  void stopBudgetApprovalListener() {
    _budgetApprovalSub?.cancel();
    _budgetApprovalSub = null;
  }

  Future<void> _persistFcmToken(String ownerUid) async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await FirebaseFirestore.instance
          .doc('EMPRESAS/$ownerUid/USERS/$ownerUid/FCM/TOKEN')
          .set({'TOKEN': token, 'ATUALIZADO_EM': FieldValue.serverTimestamp()},
              SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('persist FCM token failed: $e');
    }
  }

  Future<void> _onBudgetApprovalSnapshot(QuerySnapshot snap) async {
    if (snap.docs.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final lastSeenStr = prefs.getString(_lastSeenKey);
    DateTime lastSeen = lastSeenStr == null
        ? DateTime.now().toUtc()
        : DateTime.parse(lastSeenStr).toUtc();
    DateTime newest = lastSeen;

    // snap vem ordenado desc (mais novo primeiro). Percorre e avisa os
    // documentos mais novos que o último visto.
    final docs = snap.docs.toList();
    // Inverter para processar do mais antigo -> mais novo (ordem cronológica).
    docs.sort((a, b) =>
        _created(a).compareTo(_created(b)));

    for (final doc in docs) {
      final created = _created(doc);
      if (!created.isAfter(lastSeen)) continue;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      final title = (data['TITULO'] ?? '').toString();
      final body = (data['MENSAGEM'] ?? '').toString();
      if (title.isEmpty && body.isEmpty) continue;
      // Payload = id do orçamento, usado pelo `onDidReceiveNotificationResponse`
      // para abrir o orçamento quando o dono toca no banner da notificação.
      final orcamentoId = (data['ORCAMENTO_ID'] ?? '').toString();
      await _localNotifications.show(
        id: doc.id.hashCode,
        title: title,
        body: body,
        payload: orcamentoId.isEmpty ? null : orcamentoId,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            icon: '@mipmap/ic_launcher',
            priority: Priority.high,
            importance: Importance.high,
          ),
        ),
      );
      if (created.isAfter(newest)) newest = created;
    }

    await prefs.setString(_lastSeenKey, newest.toUtc().toIso8601String());
  }

  DateTime _created(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return DateTime.now().toUtc();
    final v = data['CRIADO_EM'];
    if (v is Timestamp) return v.toDate().toUtc();
    if (v is DateTime) return v.toUtc();
    if (v is String) return DateTime.tryParse(v)?.toUtc() ?? DateTime.now().toUtc();
    return DateTime.now().toUtc();
  }
}
