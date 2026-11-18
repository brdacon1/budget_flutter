import 'package:oflite/modules/chat_assistant/domain/entity/agent_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Contrato do assistente de IA. Mantém o histórico da sessão de chat.
abstract class ChatAiRepository {
  List<AgentMessageEntity> get history;

  /// Envia o histórico atual (com as [tools] disponíveis) e devolve a
  /// resposta do modelo: texto e/ou chamadas de tool.
  Future<Result<AgentReplyEntity>> send(
    String system, {
    List<AgentToolSpec> tools = const [],
  });

  void addMessage(AgentMessageEntity message);

  void clearHistory();
}
