/// Resultado simples de um UseCase de menu do chat.
///
/// [nextStep] → nome do próximo step do fluxo.
/// [navigation] → quando não-null, a View deve abrir uma tela/modal.
/// [pdfField] → quando editando PDF, qual campo (‘name’, ‘phone’, …).
class ChatMenuResult {
  final String nextStep;
  final String? navigation;
  final String? pdfField;

  /// Valor atual do campo (para pré-preencher formulários).
  final String? currentValue;

  const ChatMenuResult(
    this.nextStep, {
    this.navigation,
    this.pdfField,
    this.currentValue,
  });
}
