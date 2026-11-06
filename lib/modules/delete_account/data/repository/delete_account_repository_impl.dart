import 'package:oflite/modules/delete_account/data/datasource/delete_account_remote_datasource.dart';
import 'package:oflite/modules/delete_account/domain/repository/delete_account_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class DeleteAccountRepositoryImpl implements DeleteAccountRepository {
  final DeleteAccountRemoteDataSource _dataSource;

  DeleteAccountRepositoryImpl(this._dataSource);

  @override
  Future<Result<void>> deleteAccountByEmail(String email) async {
    try {
      await _dataSource.deleteAccountByEmail(email);
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
