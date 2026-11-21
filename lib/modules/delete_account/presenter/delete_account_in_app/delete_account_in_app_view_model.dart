import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/delete_account/domain/repository/delete_account_repository.dart';
import 'package:oflite/modules/delete_account/domain/usecase/delete_current_account_usecase.dart';
import 'package:oflite/modules/delete_account/presenter/delete_account_in_app/strings/delete_account_in_app_pt_string.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class DeleteAccountInAppViewModel extends ChangeNotifier {
  DeleteAccountInAppViewModel(this._repository, this._deleteCurrentAccount) {
    deleteCommand = Command0(_executeDelete);
  }

  final DeleteAccountRepository _repository;
  final DeleteCurrentAccountUsecase _deleteCurrentAccount;

  late final Command0<void> deleteCommand;

  /// Conta de e-mail/senha precisa digitar a senha para reautenticar.
  bool get needsPassword => _repository.currentProvider == 'password';

  String _password = '';
  set password(String value) {
    _password = value;
    _passwordError = null;
    notifyListeners();
  }

  String? _passwordError;
  String? get passwordError => _passwordError;

  bool _confirmed = false;
  bool get confirmed => _confirmed;
  set confirmed(bool value) {
    _confirmed = value;
    _confirmError = null;
    notifyListeners();
  }

  String? _confirmError;
  String? get confirmError => _confirmError;

  Future<Result<void>> _executeDelete() async {
    var hasError = false;
    if (needsPassword && _password.isEmpty) {
      _passwordError = DeleteAccountInAppStrings.errorPassword;
      hasError = true;
    }
    if (!_confirmed) {
      _confirmError = DeleteAccountInAppStrings.errorConfirm;
      hasError = true;
    }
    if (hasError) {
      notifyListeners();
      return Result.error(Exception('validation'));
    }

    final result = await _deleteCurrentAccount(
      password: needsPassword ? _password : null,
    );
    if (result is Error<void> &&
        result.error is DeleteAccountInvalidCredentials) {
      _passwordError = DeleteAccountInAppStrings.errorInvalidCredentials;
      notifyListeners();
    }
    return result;
  }

  bool isValidationError(Result<void>? result) =>
      result is Error<void> &&
      (_passwordError != null || _confirmError != null);

  @override
  void dispose() {
    deleteCommand.dispose();
    super.dispose();
  }
}
