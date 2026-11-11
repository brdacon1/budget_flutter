import 'dart:convert';

import 'package:dio/dio.dart';
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
    final response = await _dioClient.dioClient.post(
      url,
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
      data: jsonEncode({'email': email}),
    );

    final body = jsonDecode(jsonEncode(response.data)) as Map<String, dynamic>;
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return body;
    }
    throw Exception(body['erro'] ?? 'Erro ao excluir conta (${response.statusCode})');
  }
}
