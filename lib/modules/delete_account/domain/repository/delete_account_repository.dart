import 'package:oflite/shared/design_pattern/result.dart';

abstract class DeleteAccountRepository {
  /// Entra com e-mail/senha e exclui a própria conta.
  Future<Result<void>> deleteWithPassword(String email, String password);

  /// Entra com Google e exclui a própria conta.
  Future<Result<void>> deleteWithGoogle();
}

/// Falha de login (credenciais erradas) — distinta de erro do servidor.
class DeleteAccountInvalidCredentials implements Exception {
  const DeleteAccountInvalidCredentials();
}
