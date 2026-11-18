/// Mensagem do histórico enviado ao modelo de IA.
///
/// - `user`/`model` com [text]: conversa normal.
/// - `model` com [rawParts]: turno em que o modelo pediu tools. As parts são
///   guardadas cruas (Map) para preservar a assinatura que o Gemini exige ao
///   reenviar chamadas de função — o domínio não conhece o SDK.
/// - `tool`: resposta de uma tool ([toolName] + [toolResponse]).
enum AgentRole { user, model, tool }

class AgentMessageEntity {
  final AgentRole role;
  final String text;
  final List<Map<String, Object?>> rawParts;
  final String? toolName;
  final Map<String, Object?>? toolResponse;

  const AgentMessageEntity(
    this.role,
    this.text, {
    this.rawParts = const [],
    this.toolName,
    this.toolResponse,
  });

  const AgentMessageEntity.toolCall(this.rawParts)
    : role = AgentRole.model,
      text = '',
      toolName = null,
      toolResponse = null;

  const AgentMessageEntity.toolResult(
    String name,
    Map<String, Object?> response,
  ) : role = AgentRole.tool,
      text = '',
      rawParts = const [],
      toolName = name,
      toolResponse = response;
}
