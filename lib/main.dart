import 'dart:core';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/common/controllers/menu_controller_app.dart';
import 'package:oflite/presentations/pdf/pdf_edit/pdf_edit_view.dart';
import 'package:oflite/presentations/main_tab/main_tab_view.dart';
import 'package:oflite/presentations/subscription/subscription_view.dart';
import 'package:oflite/presentations/login/login_view.dart';
import 'package:oflite/presentations/budget/budget_list/budget_list_view.dart';
import 'package:provider/provider.dart';
import 'common/constants/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  await configureForegroundNotificationPresentationOptions();
  runApp(MyApp());
}


Future<void> configureForegroundNotificationPresentationOptions() async {
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging firebaseMessage = FirebaseMessaging.instance;
  String? deviceToken = await firebaseMessage.getToken();
  print(deviceToken);
}


class MyApp extends StatelessWidget {
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
          home: LoginView(),
          routes: {
            '/menu_tecnico': (BuildContext _) => BudgetListView(),
            '/pg-subscription': (BuildContext _) => SubscriptionView(),
            '/menu': (BuildContext _) => MainTabView(),
            '/pg-pdf-config': (BuildContext _) => const PdfEditView(),
          },
        ),
      ),
    );
  }
}

