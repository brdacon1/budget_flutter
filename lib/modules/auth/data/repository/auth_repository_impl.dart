import 'package:firebase_auth/firebase_auth.dart';
import 'package:oflite/modules/auth/data/datasource/auth_remote_datasource.dart';
import 'package:oflite/modules/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  User? get currentUser => _remote.currentUser;

  @override
  Future<User?> restoreSession() => _remote.restoreSession();

  @override
  Future<UserCredential> signInWithEmail(String email, String password) =>
      _remote.signInWithEmail(email, password);

  @override
  Future<UserCredential> signInWithGoogle() => _remote.signInWithGoogle();

  @override
  Future<UserCredential> signInWithApple() => _remote.signInWithApple();

  @override
  Future<UserCredential> createUserWithEmail(String email, String password) =>
      _remote.createUserWithEmail(email, password);

  @override
  Future<UserCredential> linkWithGoogle() => _remote.linkWithGoogle();

  @override
  Future<UserCredential> linkWithApple() => _remote.linkWithApple();

  @override
  Future<void> sendPasswordReset(String email) =>
      _remote.sendPasswordReset(email);
}
