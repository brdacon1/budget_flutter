import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/global_uid_user.dart' as uid;
import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/budget/budget_tab/presenter/budget_tab_view.dart';
import 'package:oflite/injection.dart';

/// Handler top-level (obrigatório ser top-level, não método de instância)
/// para mensagens FCM em background.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId} '
        'orcamento=${message.data['ORCAMENTO_ID']}');
  }
}

/// Implementação do gerenciamento de notificações push.
///
/// Mantém a lógica original do antigo `NotificationRepository`.
class NotificationRepositoryImpl implements NotificationRepository {
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _pendingBudgetId;
  String? _fcmToken;
  String? _boundOwnerUid;
  StreamSubscription<String>? _tokenRefreshSub;

  // ---------------------------------------------------------------------------
  // Initialize
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = IOSInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
        ));

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    unawaited(_handleInitialMessage());

    if (kIsWeb) {
      await FirebaseMessaging.instance.requestPermission();
    } else {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? granted =
            await androidPlugin?.requestNotificationsPermission();
        if (kDebugMode) {
          debugPrint('Android POST_NOTIFICATIONS concedido? $granted');
        }
        await FirebaseMessaging.instance.requestPermission();
      }
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (kDebugMode) {
        debugPrint('APNs token: $apnsToken');
      }
    }

    final String? token = await _acquireTokenWithRetry();
    _fcmToken = token;
    if (kDebugMode) {
      debugPrint('FCM token (memória volátil): $token');
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _fcmToken = t;
      final owner = _boundOwnerUid;
      if (owner != null && owner.isNotEmpty) {
        unawaited(_persistFcmToken(owner));
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Token
  // ---------------------------------------------------------------------------

  @override
  Future<String?> currentToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) return _fcmToken;
    final t = await _acquireTokenWithRetry();
    _fcmToken = t;
    return t;
  }

  Future<String?> _acquireTokenWithRetry({
    int maxAttempts = 6,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final t = await FirebaseMessaging.instance.getToken();
        if (t != null && t.isNotEmpty) {
          if (kDebugMode && attempt > 1) {
            debugPrint('FCM token obtido na tentativa $attempt');
          }
          return t;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('FCM getToken() falhou (tentativa $attempt): $e');
        }
      }
      if (attempt < maxAttempts) {
        await Future<void>.delayed(delay);
      }
    }
    if (kDebugMode) {
      debugPrint(
          'FCM token NULO após $maxAttempts tentativas. Verifique: '
          '(1) SHA-1 do certificado cadastrado no Console do Firebase; '
          '(2) google-services.json atualizado; '
          '(3) Play Services no dispositivo.');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Navigator key & pending budget
  // ---------------------------------------------------------------------------

  @override
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    tryOpenPendingBudget();
  }

  @override
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

  Future<void> _openBudget(String budgetId) async {
    final key = _navigatorKey;
    if (key == null || key.currentContext == null) {
      _pendingBudgetId = budgetId;
      return;
    }
    final owner = uid.user;
    if (owner == null || owner.isEmpty) {
      _pendingBudgetId = budgetId;
      return;
    }
    try {
      budget.IDORCAMENTO = budgetId;
      final raw = await getIt<BudgetRemoteDataSource>().getBudgetById(budgetId);
      final customer = CustomerInfo.fromMap(raw);
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
  // Foreground / Background / Terminated handlers
  // ---------------------------------------------------------------------------

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    final orcamentoId = message.data['ORCAMENTO_ID']?.toString() ?? '';

    final title = notification?.title ?? message.data['TITULO']?.toString();
    final body = notification?.body ?? message.data['MENSAGEM']?.toString();
    if (title == null && body == null) return;

    _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
        ),
      ),
      payload: orcamentoId.isEmpty ? null : orcamentoId,
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final orcamentoId = message.data['ORCAMENTO_ID']?.toString();
    if (orcamentoId != null && orcamentoId.isNotEmpty) {
      unawaited(_openBudget(orcamentoId));
    }
  }

  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return;
    final orcamentoId = message.data['ORCAMENTO_ID']?.toString();
    if (orcamentoId != null && orcamentoId.isNotEmpty) {
      _pendingBudgetId = orcamentoId;
    }
  }

  // ---------------------------------------------------------------------------
  // Budget approval listener (persist token)
  // ---------------------------------------------------------------------------

  @override
  void startBudgetApprovalListener(String ownerUid) {
    if (kIsWeb) return;
    if (ownerUid.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('startBudgetApprovalListener ignorado: ownerUid vazio');
      }
      return;
    }
    _boundOwnerUid = ownerUid.trim();
    unawaited(_persistFcmToken(_boundOwnerUid!));
    tryOpenPendingBudget();
  }

  @override
  void stopBudgetApprovalListener() {
    _boundOwnerUid = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  @override
  Future<List<String>> loadFcmTokens(String ownerUid) async {
    if (ownerUid.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('loadFcmTokens ignorado: ownerUid vazio');
      }
      return const <String>[];
    }
    final uid = ownerUid.trim();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('EMPRESAS/$uid/USERS/$uid/FCM')
          .get();
      return snap.docs.map((d) => d.id).toList(growable: false);
    } catch (e) {
      if (kDebugMode) debugPrint('load FCM tokens failed: $e');
      return const <String>[];
    }
  }

  @override
  Future<void> persistCurrentTokenToFirebase(String ownerUid) =>
      _persistFcmToken(ownerUid);

  Future<void> _persistFcmToken(String ownerUid) async {
    if (ownerUid.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('persist FCM token ignorado: ownerUid vazio');
      }
      return;
    }
    final uid = ownerUid.trim();
    if (kDebugMode) {
      debugPrint('[_persistFcmToken] inicio — uid=$uid');
    }
    try {
      final String? token = await currentToken();
      if (kDebugMode) {
        debugPrint('[_persistFcmToken] token obtido: '
            '${token == null ? "NULL" : (token.isEmpty ? "VAZIO" : token)}');
      }
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('persist FCM token: SEM TOKEN — não vai salvar nada. '
              'Provável causa: SHA-1 do certificado não cadastrado no '
              'Firebase / google-services.json desatualizado.');
        }
        return;
      }
      final db = FirebaseFirestore.instance;
      final docRef = db.doc('EMPRESAS/$uid/USERS/$uid/FCM/$token');
      if (kDebugMode) {
        debugPrint('[_persistFcmToken] gravando em: ${docRef.path}');
      }
      await docRef.set({'TOKEN': token}, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('FCM token SALVO na lista: '
            'EMPRESAS/$uid/USERS/$uid/FCM/$token');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('persist FCM token failed: $e');
        debugPrint('stack: $st');
      }
    }
  }
}
