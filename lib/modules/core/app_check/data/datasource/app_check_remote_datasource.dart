import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Firebase App Check (SDK externo). Protege a cota do Firebase AI Logic:
/// só o app legítimo consegue chamar o modelo.
class AppCheckRemoteDataSource {
  /// Debug token fixo (segredo — NÃO versionar). Passe no run:
  ///   `--dart-define=APP_CHECK_DEBUG_TOKEN=<uuid>`
  /// e cadastre o mesmo uuid no Console → App Check → Apps → Gerenciar tokens
  /// de depuração (iOS e Android). Vazio → o SDK gera um token aleatório por
  /// instalação e o imprime no log nativo.
  static const _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

  Future<void> activate() {
    final token = _debugToken.isEmpty ? null : _debugToken;
    if (kDebugMode) {
      // Mostra só o fim do token (segredo) para conferir com o console.
      debugPrint(
        '[AppCheck] debug token via dart-define: '
        '${token == null ? 'AUSENTE (SDK gera um aleatório)' : '…${token.substring(token.length - 4)}'}',
      );
    }
    return FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(debugToken: token)
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider(debugToken: token)
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }
}
