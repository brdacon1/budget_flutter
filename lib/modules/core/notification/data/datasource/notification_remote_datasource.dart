import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Fonte externa para notificações push (FCM) e locais.
///
/// Não conhece entidades de negócio; trabalha apenas com tipos primitivos
/// e objetos do SDK (RemoteMessage, Map, String).
class NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  // ---------------------------------------------------------------------------
  // Local notifications
  // ---------------------------------------------------------------------------

  Future<bool?> requestAndroidNotificationPermission() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return androidPlugin?.requestNotificationsPermission();
  }

  Future<bool?> initializeLocalNotifications(
    InitializationSettings settings,
    void Function(NotificationResponse)? onTap,
  ) {
    return _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onTap,
    );
  }

  Future<void> createNotificationChannel(
    String channelId,
    String channelName,
    Importance importance,
  ) async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(channelId, channelName, importance: importance),
    );
  }

  Future<void> showLocalNotification({
    required int id,
    String? title,
    String? body,
    required NotificationDetails notificationDetails,
    String? payload,
  }) {
    return _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------------
  // FCM
  // ---------------------------------------------------------------------------

  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) {
    return _messaging.setForegroundNotificationPresentationOptions(
      alert: alert,
      badge: badge,
      sound: sound,
    );
  }

  Future<String?> getFcmToken() => _messaging.getToken();

  Stream<String> get fcmTokenRefresh => _messaging.onTokenRefresh;

  Future<void> requestFcmPermission({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) {
    return _messaging.requestPermission(
      alert: alert,
      badge: badge,
      sound: sound,
    );
  }

  Future<String?> getApnsToken() => _messaging.getAPNSToken();

  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  // ---------------------------------------------------------------------------
  // Firestore — tokens
  // ---------------------------------------------------------------------------

  Future<void> persistFcmToken(String ownerUid, String token) async {
    final docRef = _firestore.doc('EMPRESAS/$ownerUid/USERS/$ownerUid/FCM/$token');
    await docRef.set({'TOKEN': token}, SetOptions(merge: true));
  }

  Future<List<String>> loadFcmTokens(String ownerUid) async {
    final snap = await _firestore
        .collection('EMPRESAS/$ownerUid/USERS/$ownerUid/FCM')
        .get();
    return snap.docs.map((d) => d.id).toList(growable: false);
  }
}
