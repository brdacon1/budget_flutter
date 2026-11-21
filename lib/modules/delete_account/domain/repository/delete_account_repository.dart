import 'package:oflite/shared/design_pattern/result.dart';

abstract class DeleteAccountRepository {
  /// Entra com e-mail/senha e exclui a própria conta.
  Future<Result<void>> deleteWithPassword(String email, String password);

  /// Entra com Google e exclui a própria conta.
  Future<Result<void>> deleteWithGoogle();

  /// Provedor do usuário logado no app (`password`, `google.com`, `apple.com`).
  String? get currentProvider;

  /// Reautentica o usuário logado no app e exclui a própria conta.
  Future<Result<void>> deleteCurrentUser({String? password});
}

/// Falha de login (credenciais erradas) — distinta de erro do servidor.
class DeleteAccountInvalidCredentials implements Exception {
  const DeleteAccountInvalidCredentials();
}
