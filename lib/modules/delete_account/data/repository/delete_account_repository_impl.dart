import 'package:firebase_auth/firebase_auth.dart';
import 'package:oflite/modules/delete_account/data/datasource/delete_account_remote_datasource.dart';
import 'package:oflite/modules/delete_account/domain/repository/delete_account_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class DeleteAccountRepositoryImpl implements DeleteAccountRepository {
  final DeleteAccountRemoteDataSource _dataSource;

  DeleteAccountRepositoryImpl(this._dataSource);

  static const _invalidCredentialCodes = {
    'invalid-credential',
    'wrong-password',
    'user-not-found',
    'invalid-email',
    'user-disabled',
  };

  @override
  Future<Result<void>> deleteWithPassword(String email, String password) =>
      _run(() => _dataSource.deleteWithPassword(email, password));

  @override
  Future<Result<void>> deleteWithGoogle() =>
      _run(_dataSource.deleteWithGoogle);

  @override
  String? get currentProvider => _dataSource.currentProvider;

  @override
  Future<Result<void>> deleteCurrentUser({String? password}) =>
      _run(() => _dataSource.deleteCurrentUser(password: password));

  Future<Result<void>> _run(Future<void> Function() action) async {
    try {
      await action();
      return Result.ok(null);
    } on FirebaseAuthException catch (e) {
      if (_invalidCredentialCodes.contains(e.code)) {
        return Result.error(const DeleteAccountInvalidCredentials());
      }
      return Result.error(Exception(e.code));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
