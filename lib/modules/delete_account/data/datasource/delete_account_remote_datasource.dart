import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:oflite/shared/utils/interceptor/dio_client.dart';

/// Fonte de dados remota para exclusão de conta via Cloud Function.
///
/// Não conhece models de negócio; trabalha apenas com tipos
/// primitivos e `Map<String, dynamic>`.
class DeleteAccountRemoteDataSource {
  static const String _baseUrl =
      // ignore: unintended_html_in_doc_comment
      'https://southamerica-east1-orcamentofacil-lite.cloudfunctions.net';

  final DioClient _dioClient = DioClient();

  Future<Map<String, dynamic>> deleteAccountByEmail(String email) async {
    final url = '$_baseUrl/deleteAccount';
    try {
      final response = await _dioClient.dioClient.post(
        url,
        options: Options(
          contentType: 'application/json',
          headers: {'Accept': 'application/json'},
          // Em Web, `withCredentials: false` evita que o browser envie cookies
          // ou credenciais, o que pode interferir no CORS quando a origem do
          // app é diferente da Cloud Function.
          extra: kIsWeb ? {'withCredentials': false} : null,
        ),
        data: {'email': email},
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : jsonDecode(jsonEncode(response.data)) as Map<String, dynamic>;

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return body;
      }
      throw Exception(body['erro'] ?? 'Erro ao excluir conta (${response.statusCode})');
    } on DioException catch (e) {
      // Quando o CORS bloqueia a requisição no navegador, o Dio retorna um
      // erro de conexão/timeout com status nulo. Subimos uma mensagem mais
      // clara para facilitar o diagnóstico.
      if (kIsWeb && e.response == null) {
        throw Exception(
          'Não foi possível conectar ao servidor. '
          'Verifique as configurações de CORS da Cloud Function.',
        );
      }
      final data = e.response?.data;
      final msg = data is Map<String, dynamic>
          ? data['erro']
          : null;
      throw Exception(msg ?? e.message ?? 'Erro ao excluir conta');
    }
  }
}
