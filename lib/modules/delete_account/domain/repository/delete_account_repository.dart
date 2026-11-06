import 'package:oflite/shared/design_pattern/result.dart';

abstract class DeleteAccountRepository {
  Future<Result<void>> deleteAccountByEmail(String email);
}
