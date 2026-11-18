/// Tools (function calling) que a IA pode pedir para o app executar.
///
/// Declaradas como dados neutros: o datasource converte para o formato do
/// SDK — o domínio não importa `firebase_ai`.
class AgentToolSpec {
  final String name;
  final String description;

  /// `{param: {'type': 'enum', 'values': [...], 'description': '...'}}`
  /// ou `{param: {'type': 'string', 'description': '...'}}`.
  final Map<String, Map<String, Object>> params;

  const AgentToolSpec(this.name, this.description, this.params);
}

/// Chamada de tool pedida pelo modelo.
class AgentToolCallEntity {
  final String name;
  final Map<String, Object?> args;

  const AgentToolCallEntity(this.name, this.args);
}

/// Resposta do modelo: texto e/ou chamadas de tool.
class AgentReplyEntity {
  final String text;
  final List<AgentToolCallEntity> toolCalls;

  const AgentReplyEntity({this.text = '', this.toolCalls = const []});
}

/// Resultado de um turno do agente para o ViewModel.
///
/// [menuOption] preenchido → o VM abre o fluxo determinístico equivalente à
/// opção do menu principal (`'1'..'4'`).
class AgentTurnResult {
  final String text;
  final String? menuOption;

  const AgentTurnResult({this.text = '', this.menuOption});
}
