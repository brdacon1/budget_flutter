/// Limites dos comprovantes (§15.2 do plano).
abstract final class PaymentProofLimits {
  /// Imagens por envio.
  static const maxImagesPerSend = 2;

  /// Comprovantes por orçamento.
  static const maxPerBudget = 15;

  /// Tamanho máximo de cada arquivo (bytes).
  static const maxFileBytes = 10 * 1024 * 1024;

  static const imageExtensions = {'jpg', 'jpeg', 'png', 'heic', 'heif'};
}
