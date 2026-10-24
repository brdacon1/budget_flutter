import 'dart:core';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/shared/common/constants/environment.dart';
import 'package:oflite/shared/common/controllers/menu_controller_app.dart';
import 'package:oflite/modules/core/services/data/service/notification_service.dart';
import 'package:provider/provider.dart';
import 'app_routes.dart';
import 'injection.dart';
import 'shared/common/constants/constants.dart';

/// Chave global do navigator do app. Compartilhada com o
/// `NotificationService` para que, ao tocar no banner de uma notificação de
/// aprovação/reprovação vinda do fluxo Web, o app abra o orçamento
/// correspondente (`BudgetTabView`).
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencyInjection();

  // Inicializa o Firebase sempre (mobile e web).
  await Firebase.initializeApp();

  // Ads e notificações são mobile-only. No web esses plugins não existem
  // e lançam exceção, causando tela branca se o entry point mobile for
  // compilado para web por engano.
  if (!kIsWeb) {
    await MobileAds.instance.initialize();

    if (Environment.instance.environment == 'development') {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _kTestDeviceIds),
      );
    }

    await NotificationService.instance.initialize();
    NotificationService.instance.setNavigatorKey(globalNavigatorKey);
  }

  // Carrega as chaves do ambiente (env/*.json). O ambiente é escolhido
  // automaticamente: release -> produção, debug -> desenvolvimento.
  await Environment.instance.initialize();

  runApp(const MyApp());
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MenuControllerApp(),
        ),
      ],
      child: AdaptiveTheme(
        light: ThemeData.light().copyWith(
          scaffoldBackgroundColor: creamColor,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
              .apply(bodyColor: Colors.black),
          canvasColor: snowColor,
        ),
        dark: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: bgColor,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
              .apply(bodyColor: Colors.white),
          canvasColor: secondaryColor,
        ),
        initial: AdaptiveThemeMode.dark,
        builder: (theme, darkTheme) => MaterialApp(
          title: 'Orçamento de Vendas - PDF',
          theme: theme,
          darkTheme: darkTheme,
          debugShowCheckedModeBanner: false,
          navigatorKey: globalNavigatorKey,
          initialRoute: AppRoute.login.path,
          routes: appRoutes,
        ),
      ),
    );
  }
}

