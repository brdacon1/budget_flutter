import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google Sign-In retornou idToken nulo ou vazio.');
    }
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
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
    final result = await _auth.signInWithCredential(
      OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      ),
    );

    // A Apple só envia o nome na primeira autorização: grava no Firebase.
    final name = [
      apple.givenName,
      apple.familyName,
    ].whereType<String>().join(' ').trim();
    final user = result.user;
    if (name.isNotEmpty && (user?.displayName ?? '').isEmpty) {
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
