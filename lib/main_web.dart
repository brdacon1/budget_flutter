import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/constants/environment.dart';
import 'package:oflite/presentations/budget_web/budget_web_app/budget_web_app_view.dart';

/// Entry point **Web** do fluxo público de orçamento.
///
/// Diferente do `main.dart` (aplicativo mobile completo), este entry point
/// publica **somente** o fluxo de orçamento compartilhável. As demais telas
/// do app mobile nunca ficam acessíveis no Web — não há rotas nem navegação
/// para o restante do aplicativo.
///
/// Build Web com entry point separado:
/// ```bash
/// flutter build web --target lib/main_web.dart
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configuração Web do Firebase (orçamento compartilhável). No Web é
  // obrigatório passar o [FirebaseOptions] — o app mobile continua usando
  // `Firebase.initializeApp()` sem options (config via google-services /
  // Info.plist). Como este entry point é Web-only, isto não afeta o mobile.
  assert(kIsWeb, 'main_web.dart só deve ser usado no Flutter Web');
  await Firebase.initializeApp(options: _webFirebaseOptions);
  await Environment.instance.initialize();
  runApp(const BudgetWebApp());
}

/// Configuração Web do Firebase (projeto `orcamentofacil-lite`).
/// Mantida aqui (e não num `firebase_options.dart` global) para não alterar o
/// `main.dart`/mobile.
const FirebaseOptions _webFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyCRlK8XuBVY1jGFOaTArxKFdd95B9wQm1E',
  authDomain: 'orcamentofacil-lite.firebaseapp.com',
  databaseURL: 'https://orcamentofacil-lite.firebaseio.com',
  projectId: 'orcamentofacil-lite',
  storageBucket: 'orcamentofacil-lite.appspot.com',
  messagingSenderId: '157009524901',
  appId: '1:157009524901:web:064e347c4982ebaa4df54c',
  measurementId: 'G-9R8QVPZTN5',
);

class BudgetWebApp extends StatelessWidget {
  const BudgetWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData.light().copyWith(
        scaffoldBackgroundColor: creamColor,
        textTheme:
            GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
                .apply(bodyColor: Colors.black),
        canvasColor: snowColor,
      ),
      dark: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgColor,
        textTheme:
            GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
                .apply(bodyColor: Colors.white),
        canvasColor: secondaryColor,
      ),
      initial: AdaptiveThemeMode.dark,
      builder: (theme, darkTheme) => MaterialApp(
        title: 'Orçamento',
        debugShowCheckedModeBanner: false,
        // Sem rotas nomeadas do app mobile — somente o fluxo de orçamento.
        home: const BudgetWebAppView(),
      ),
    );
  }
}
