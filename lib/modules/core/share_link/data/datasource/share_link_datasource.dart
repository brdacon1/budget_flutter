import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:oflite/shared/common/utils/dio_client.dart';

/// Fonte de dados do link público de orçamento.
///
/// Pede à Cloud Function `createShareLink` um código curto, com escopo de um
/// único orçamento. O ID Token do dono só vai para a Function (validado no
/// servidor junto do App Check) — nunca entra na URL compartilhada.
class ShareLinkDataSource {
  static const String functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue:
        'https://southamerica-east1-orcamentofacil-lite.cloudfunctions.net',
  );

  final Dio _dio = DioClient().dioClient;

  /// Retorna o código do link ou `null` (sem login, sem App Check ou erro).
  Future<String?> createShareCode({required String budgetId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final idToken = await user.getIdToken();
      final appCheckToken = await FirebaseAppCheck.instance.getToken();
      if (idToken == null || appCheckToken == null) return null;

      final response = await _dio.post(
        '$functionsBaseUrl/createShareLink',
        data: {'budgetId': budgetId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'X-Firebase-AppCheck': appCheckToken,
            'Content-Type': 'application/json',
          },
          validateStatus: (_) => true,
        ),
      );
      final data = response.data;
      if (response.statusCode == 200 && data is Map && data['ok'] == true) {
        return data['code'] as String?;
      }
      debugPrint('[ShareLink] createShareLink ${response.statusCode}: $data');
      return null;
    } catch (e) {
      debugPrint('[ShareLink] createShareLink erro: $e');
      return null;
    }
  }
}
