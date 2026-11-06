import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fonte de dados remota para exclusão de conta via Cloud Function.
///
/// Não conhece models de negócio; trabalha apenas com tipos
/// primitivos e `Map<String, dynamic>`.
class DeleteAccountRemoteDataSource {
  static const String _baseUrl =
      // ignore: unintended_html_in_doc_comment
      'https://southamerica-east1-orcamentofacil-lite.cloudfunctions.net';

  Future<Map<String, dynamic>> deleteAccountByEmail(String email) async {
    final url = Uri.parse('$_baseUrl/deleteAccount');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw Exception(body['erro'] ?? 'Erro ao excluir conta (${response.statusCode})');
  }
}
