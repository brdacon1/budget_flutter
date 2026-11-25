import 'dart:async';
import 'dart:core';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/utils/poppins_text_theme.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/core/app_check/domain/repository/app_check_repository.dart';
import 'package:oflite/modules/core/crashlytics/domain/repository/crashlytics_repository.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/shared/common/constants/environment.dart';

import 'app_routes.dart';
import 'shared/common/constants/colors.dart';

/// Chave global do navigator do app. Compartilhada com o
/// `NotificationRepository` para que, ao tocar no banner de uma notificação de
/// aprovação/reprovação vinda do fluxo Web, o app abra o orçamento
/// correspondente (`BudgetTabView`).
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _lockTabletToLandscape();
  setupDependencyInjection();

  // Firebase é o único init crítico; o restante nunca pode travar o boot.
  await Firebase.initializeApp();

  if (!kIsWeb) {
    await _safe('Crashlytics', () => getIt<CrashlyticsRepository>().initialize());
    await _safe('AppCheck', () => getIt<AppCheckRepository>().initialize());
    // serverClientId é OBRIGATÓRIO no Android (CredentialManager).
    await _safe(
      'GoogleSignIn',
      () => GoogleSignIn.instance.initialize(
        serverClientId:
            '157009524901-or1nm106j8mums7rd0448ruin2slarr7.apps.googleusercontent.com',
      ),
    );
  }

  await _safe('Environment', () => Environment.instance.initialize());

  // Sobe a UI já; Ads e notificações (que podem levar segundos: APNs/FCM com
  // retry) inicializam em background sem bloquear nem derrubar o app.
  runApp(const MyApp());

  if (!kIsWeb) {
    getIt<NotificationRepository>().setNavigatorKey(globalNavigatorKey);
    unawaited(_safe('Notificações', () => getIt<NotificationRepository>().initialize()));
    unawaited(_safe('Ads', () async {
      await getIt<AdsRepository>().initialize();
      if (Environment.instance.environment == 'development') {
        await getIt<AdsRepository>().setTestDevices(_kTestDeviceIds);
      }
    }));
  }
}

/// Executa uma etapa de inicialização sem nunca propagar erro.
Future<void> _safe(String name, Future<void> Function() step) async {
  try {
    await step();
  } catch (e, s) {
    debugPrint('Erro na inicialização de $name: $e');
    try {
      getIt<CrashlyticsRepository>().recordError(e, s);
    } catch (_) {}
  }
}

/// Tablet (menor lateral >= 600 dp) abre sempre deitado; celular não muda.
/// No iPad a trava também está no Info.plist; aqui cobre tablets Android.
void _lockTabletToLandscape() {
  if (kIsWeb) return;
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  if (view.physicalSize.shortestSide / view.devicePixelRatio < 600) return;
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

/// IDs de dispositivos de teste (hash do AdMob) para servir anúncios de
/// teste mesmo usando blocos reais em desenvolvimento.
///
/// Descubra o ID do seu aparelho rodando em desenvolvimento: o AdMob loga
/// algo como:
///   I/Ads: Use RequestConfiguration.Builder(...).setTestDeviceIds(Arrays.asList("33BE2250B43518CC...")) to get test ads on this device.
/// Copie esse hash e cole na lista abaixo.
const _kTestDeviceIds = <String>[
  // 'SEU_DEVICE_ID_AQUI',
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData.light().copyWith(
        scaffoldBackgroundColor: creamColor,
        textTheme: poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.black),
        canvasColor: snowColor,
      ),
      dark: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgColor,
        textTheme: poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white),
        canvasColor: secondaryColor,
      ),
      initial: AdaptiveThemeMode.dark,
      builder:
          (theme, darkTheme) => MaterialApp(
            title: 'Orçamento de Vendas - PDF',
            theme: theme,
            darkTheme: darkTheme,
            debugShowCheckedModeBanner: false,
            navigatorKey: globalNavigatorKey,
            initialRoute: AppRoute.auth.path,
            routes: appRoutes,
            // Toque fora de um campo fecha o teclado nativo (iOS/Android).
            builder:
                (context, child) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: child,
                ),
          ),
    );
  }
}
