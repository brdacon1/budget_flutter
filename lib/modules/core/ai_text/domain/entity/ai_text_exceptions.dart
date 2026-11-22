/// Limite diário de chamadas de texto com IA atingido.
class AiTextDailyLimitException implements Exception {
  const AiTextDailyLimitException();
}

/// A IA respondeu vazio.
class AiTextEmptyException implements Exception {
  const AiTextEmptyException();
}
