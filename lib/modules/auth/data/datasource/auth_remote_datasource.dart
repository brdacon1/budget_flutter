import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Único ponto que conversa com FirebaseAuth e SDKs de login social.
/// Lança exceções técnicas (FirebaseAuthException, GoogleSignInException,
/// SignInWithAppleAuthorizationException).
class AuthRemoteDataSource {
  AuthRemoteDataSource({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _auth.currentUser;

  /// No iOS o Firebase restaura a sessão do Keychain de forma assíncrona:
  /// `currentUser` pode ser null logo na abertura. Aguarda o primeiro evento.
  Future<User?> restoreSession() async =>
      _auth.currentUser ??
      await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

  Future<UserCredential> createUserWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

  Future<AuthCredential> _googleCredential() async {
    final googleUser = await _googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google Sign-In retornou idToken nulo ou vazio.');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  Future<UserCredential> signInWithGoogle() async =>
      _auth.signInWithCredential(await _googleCredential());

  /// Vincula o Google à conta logada (cadastro e-mail + rede social).
  Future<UserCredential> linkWithGoogle() async =>
      _auth.currentUser!.linkWithCredential(await _googleCredential());

  /// Vincula a Apple à conta logada (cadastro e-mail + rede social).
  Future<UserCredential> linkWithApple() async {
    final rawNonce = _nonce();
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final idToken = apple.identityToken;
    if (idToken == null) throw Exception('Apple não retornou identityToken.');
    return _auth.currentUser!.linkWithCredential(
      AppleAuthProvider.credentialWithIDToken(
        idToken,
        rawNonce,
        AppleFullPersonName(),
      ),
    );
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _nonce();
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    // A Apple só envia o nome na 1ª autorização deste Apple ID no app.
    debugPrint(
      '[AppleSignIn] nome recebido: '
      '"${apple.givenName ?? ''}" "${apple.familyName ?? ''}"',
    );
    final idToken = apple.identityToken;
    if (idToken == null) throw Exception('Apple não retornou identityToken.');

    // credentialWithIDToken leva o nome ao Firebase (vira displayName).
    final result = await _auth.signInWithCredential(
      AppleAuthProvider.credentialWithIDToken(
        idToken,
        rawNonce,
        AppleFullPersonName(
          givenName: apple.givenName,
          familyName: apple.familyName,
        ),
      ),
    );

    // Garante o displayName quando a Apple mandou o nome.
    final name = [
      apple.givenName,
      apple.familyName,
    ].whereType<String>().join(' ').trim();
    final user = result.user;
    if (name.isNotEmpty && user?.displayName != name) {
      await user?.updateDisplayName(name);
      await user?.reload();
    }
    return result;
  }

  String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}
