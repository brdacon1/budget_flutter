import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:oflite/shared/common/utils/dio_client.dart';

/// Fonte de dados remota para exclusão de conta via Cloud Function.
///
/// O usuário precisa **entrar na conta** (e-mail/senha ou Google) nesta
/// página; a Function `deleteAccount` exclui apenas o usuário do ID Token
/// (login recente). Saber só o e-mail não basta para excluir ninguém.
class DeleteAccountRemoteDataSource {
  static const String _baseUrl =
      'https://southamerica-east1-orcamentofacil-lite.cloudfunctions.net';

  final DioClient _dioClient = DioClient();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> deleteWithPassword(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _deleteSignedIn(cred.user);
  }

  Future<void> deleteWithGoogle() async {
    final cred = await _auth.signInWithPopup(GoogleAuthProvider());
    await _deleteSignedIn(cred.user);
  }

  Future<void> _deleteSignedIn(User? user) async {
    if (user == null) throw Exception('auth');
    try {
      final idToken = await user.getIdToken(true);
      final response = await _dioClient.dioClient.post(
        '$_baseUrl/deleteAccount',
        options: Options(
          contentType: 'application/json',
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          extra: kIsWeb ? {'withCredentials': false} : null,
          validateStatus: (_) => true,
        ),
        data: const <String, dynamic>{},
      );
      final code = response.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        final data = response.data;
        throw Exception(
          (data is Map ? data['erro'] : null) ?? 'Erro ao excluir conta ($code)',
        );
      }
    } finally {
      // Conta já excluída ou falha: não deixa sessão aberta na página.
      await _auth.signOut();
    }
  }
}
