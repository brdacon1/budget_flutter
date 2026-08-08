import 'dart:core';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/common/constants/environment.dart';
import 'package:oflite/common/controllers/menu_controller_app.dart';
import 'package:oflite/presentations/pdf/pdf_edit/pdf_edit_view.dart';
import 'package:oflite/presentations/main_tab/main_tab_view.dart';
import 'package:oflite/presentations/subscription/subscription_view.dart';
import 'package:oflite/presentations/login/login_view.dart';
import 'package:oflite/presentations/budget/budget_list/budget_list_view.dart';
import 'package:oflite/presentations/terms_conditions/terms_conditions_view.dart';
import 'package:provider/provider.dart';
import 'common/constants/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o Firebase e os ads em paralelo para não travar a splash.
  await Future.wait([
    Firebase.initializeApp(),
    MobileAds.instance.initialize(),
  ]);
  // Carrega as chaves do ambiente (env/*.json). O ambiente é escolhido
  // automaticamente: release -> produção, debug -> desenvolvimento.
  await Environment.instance.initialize();
  // Em desenvolvimento, registra os dispositivos de teste para que os blocos
  // reais do AdMob sirvam anúncios de teste (sem risco de cliques inválidos
  // e com preenchimento garantido no emulador). O ID de cada aparelho aparece
  // no logcat na primeira falha de carga (linha "To get test ads on this
  // device, use: <ID>"). Adicione-o em [_kTestDeviceIds].
  if (Environment.instance.environment == 'development') {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: _kTestDeviceIds),
    );
  }
  // Configuração de notificações em background (não bloqueia o runApp).
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  configureForegroundNotificationPresentationOptions();
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

Future<void> configureForegroundNotificationPresentationOptions() async {
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging firebaseMessage = FirebaseMessaging.instance;
  String? deviceToken = await firebaseMessage.getToken();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
          home: const LoginView(),
          routes: {
            '/menu_tecnico': (BuildContext _) => const BudgetListView(),
            '/pg-subscription': (BuildContext _) => const SubscriptionView(),
            '/menu': (BuildContext _) => const MainTabView(),
            '/pg-pdf-config': (BuildContext _) => const PdfEditView(),
            TermsConditionsView.routeName: (BuildContext _) =>
                const TermsConditionsView(),
          },
        ),
      ),
    );
  }
}

