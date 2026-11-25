import 'package:firebase_auth/firebase_auth.dart';

/// Autenticação (Firebase Auth + provedores sociais).
/// Repassa as exceções técnicas para a camada de cima mapear a mensagem.
abstract class AuthRepository {
  User? get currentUser;
  Future<User?> restoreSession();
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithApple();
  Future<UserCredential> createUserWithEmail(String email, String password);
  Future<UserCredential> linkWithGoogle();
  Future<UserCredential> linkWithApple();
  Future<void> sendPasswordReset(String email);
}
