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
}
