/// O usuário fechou o fluxo de login social (picker do Google/Apple).
/// Não é erro: a tela volta ao estado inicial sem mensagem.
class AuthCancelledException implements Exception {}
