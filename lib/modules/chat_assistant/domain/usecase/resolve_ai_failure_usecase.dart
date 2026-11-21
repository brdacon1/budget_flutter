import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// O que fazer quando a IA falha (erro, timeout, cota, limite diário).
class AiFailureDecision {
  /// Mensagem para o chat.
  final String message;

  /// true → a sessão volta ao chat determinístico (igual ao usuário free).
  final bool fallbackToStandard;

  const AiFailureDecision(this.message, {required this.fallbackToStandard});
}

/// Rede de segurança do chat com IA: uma falha isolada só avisa; falhas
/// seguidas (ou limite diário) fazem o chat seguir no modo padrão — o mesmo
/// fluxo do usuário free — até a conversa ser reiniciada.
class ResolveAiFailureUsecase {
  /// Falhas seguidas toleradas antes de cair no modo padrão.
  static const maxConsecutiveFailures = 2;

  const ResolveAiFailureUsecase();

  AiFailureDecision call(Exception error, {required int consecutiveFailures}) {
    if (error is AiDailyLimitException) {
      return AiFailureDecision(
        ChatAssistantStrings.aiDailyLimit,
        fallbackToStandard: true,
      );
    }
    if (consecutiveFailures >= maxConsecutiveFailures) {
      return AiFailureDecision(
        ChatAssistantStrings.aiUnavailable,
        fallbackToStandard: true,
      );
    }
    return AiFailureDecision(
      ChatAssistantStrings.aiFallback,
      fallbackToStandard: false,
    );
  }
}
