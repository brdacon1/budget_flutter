import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/shared/common/utils/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  /// Provedor de login do usuário logado no app: `password`, `google.com`
  /// ou `apple.com`. `null` se não houver sessão.
  String? get currentProvider {
    final providers = _auth.currentUser?.providerData ?? const [];
    for (final id in const ['apple.com', 'google.com', 'password']) {
      if (providers.any((p) => p.providerId == id)) return id;
    }
    return providers.isEmpty ? null : providers.first.providerId;
  }

  /// Exclusão dentro do app (iOS/Android): reautentica o usuário logado
  /// (a Function exige login recente) e exclui a própria conta.
  Future<void> deleteCurrentUser({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('auth');
    switch (currentProvider) {
      case 'password':
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email ?? '',
            password: password ?? '',
          ),
        );
      case 'google.com':
        final googleUser = await GoogleSignIn.instance.authenticate();
        final idToken = googleUser.authentication.idToken;
        await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      case 'apple.com':
        final rawNonce = _nonce();
        final apple = await SignInWithApple.getAppleIDCredential(
          scopes: const [],
          nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        );
        await user.reauthenticateWithCredential(
          OAuthProvider('apple.com').credential(
            idToken: apple.identityToken,
            rawNonce: rawNonce,
            accessToken: apple.authorizationCode,
          ),
        );
    }
    try {
      await _deleteSignedIn(_auth.currentUser);
    } finally {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
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
