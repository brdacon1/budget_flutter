import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/delete_account/domain/repository/delete_account_repository.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class DeleteAccountViewModel extends ChangeNotifier {
  final DeleteAccountRepository _repository;

  DeleteAccountViewModel(this._repository) {
    deleteCommand = Command1(_executeDelete);
  }

  /// `true` = entrar com Google; `false` = e-mail e senha.
  late final Command1<void, bool> deleteCommand;

  String _email = '';
  String get email => _email;
  set email(String value) {
    _email = value;
    _emailError = null;
    notifyListeners();
  }

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

  String? _emailError;
  String? get emailError => _emailError;

  String? _confirmError;
  String? get confirmError => _confirmError;

  bool _success = false;
  bool get success => _success;

  void clearErrors() {
    _emailError = null;
    _passwordError = null;
    _confirmError = null;
    notifyListeners();
  }

  Future<Result<void>> _executeDelete(bool withGoogle) async {
    _success = false;
    bool hasError = false;
    final email = _email.trim();

    if (!withGoogle) {
      if (email.isEmpty) {
        _emailError = 'Informe o e-mail cadastrado.';
        hasError = true;
      } else if (!_isValidEmail(email)) {
        _emailError = 'Informe um e-mail válido.';
        hasError = true;
      }
      if (_password.isEmpty) {
        _passwordError = 'Informe a senha da conta.';
        hasError = true;
      }
    }

    if (!_confirmed) {
      _confirmError = 'Você precisa confirmar para prosseguir.';
      hasError = true;
    }

    if (hasError) {
      notifyListeners();
      return Result.error(Exception('validation'));
    }

    final result = withGoogle
        ? await _repository.deleteWithGoogle()
        : await _repository.deleteWithPassword(email, _password);

    if (result is Ok<void>) {
      _success = true;
    } else if (result is Error<void> &&
        result.error is DeleteAccountInvalidCredentials) {
      _passwordError = 'E-mail ou senha incorretos.';
    }

    notifyListeners();
    return result;
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }

  @override
  void dispose() {
    deleteCommand.dispose();
    super.dispose();
  }
}
