import 'package:flutter/material.dart';
import 'package:oflite/modules/delete_account/domain/repository/delete_account_repository.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class DeleteAccountViewModel extends ChangeNotifier {
  final DeleteAccountRepository _repository;

  DeleteAccountViewModel(this._repository) {
    deleteCommand = Command1(_executeDelete);
  }

  late final Command1<void, String> deleteCommand;

  String _email = '';
  String get email => _email;
  set email(String value) {
    _email = value;
    _emailError = null;
    notifyListeners();
  }

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
    _confirmError = null;
    notifyListeners();
  }

  Future<Result<void>> _executeDelete(String email) async {
    _success = false;
    bool hasError = false;

    if (email.trim().isEmpty) {
      _emailError = 'Informe o e-mail cadastrado.';
      hasError = true;
    } else if (!_isValidEmail(email.trim())) {
      _emailError = 'Informe um e-mail válido.';
      hasError = true;
    }

    if (!_confirmed) {
      _confirmError = 'Você precisa confirmar para prosseguir.';
      hasError = true;
    }

    if (hasError) {
      notifyListeners();
      return Result.error(Exception('validation'));
    }

    final result = await _repository.deleteAccountByEmail(email.trim());

    if (result is Ok<void>) {
      _success = true;
    } else if (result is Error<void>) {
      _success = false;
      final msg = result.error.toString();
      if (msg.contains('Usuário não encontrado') || msg.contains('404')) {
        _emailError = 'Nenhuma conta encontrada com este e-mail.';
      }
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
