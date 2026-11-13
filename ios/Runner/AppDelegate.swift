import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configura o delegate do UserNotifications ANTES do Firebase, pois
    // FirebaseAppDelegateProxyEnabled=false exige controle manual.
    UNUserNotificationCenter.current().delegate = self

    FirebaseApp.configure()

    // Registra o app para notificações remotas (APNs). O token APNs será
    // repassado ao Firebase Messaging em didRegisterForRemoteNotifications.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Pass APNs token to Firebase Messaging.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Garante que o FCM seja notificado quando o usuário tocar na notificação
  // vinda do APNs (necessário porque FirebaseAppDelegateProxyEnabled=false).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler()
  }

  // Show notifications while app is in foreground.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([[.alert, .sound, .badge]])
  }
}
