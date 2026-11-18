/// Mensagem do histórico enviado ao modelo de IA.
enum AgentRole { user, model }

class AgentMessageEntity {
  final AgentRole role;
  final String text;

  const AgentMessageEntity(this.role, this.text);
}
