import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  /// Inicializa tudo. Deve ser chamado após `Firebase.initializeApp()`.
  Future<void> initialize() async {
    // 1) Inicializa o plugin de notificações locais (Android usa o ícone do app).
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings: initSettings);

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
}
