import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';

/// Tools (function calling) que a IA pode pedir para o app executar.
///
/// Declaradas como dados neutros: o datasource converte para o formato do
/// SDK — o domínio não importa `firebase_ai`.
class AgentToolSpec {
  final String name;
  final String description;

  /// `{param: {'type': 'enum'|'string'|'number'|'boolean', 'values': [...],
  /// 'description': '...', 'required': true}}`. Sem `required` → opcional.
  final Map<String, Map<String, Object>> params;

  const AgentToolSpec(this.name, this.description, this.params);
}

/// Chamada de tool pedida pelo modelo.
class AgentToolCallEntity {
  final String name;
  final Map<String, Object?> args;

  const AgentToolCallEntity(this.name, this.args);
}

/// Resposta do modelo: texto, chamadas de tool e as parts cruas do turno.
class AgentReplyEntity {
  final String text;
  final List<AgentToolCallEntity> toolCalls;
  final List<Map<String, Object?>> rawParts;

  const AgentReplyEntity({
    this.text = '',
    this.toolCalls = const [],
    this.rawParts = const [],
  });
}

/// Ação de escrita aguardando o toque do usuário em "Confirmar".
class AgentPendingAction {
  final String toolName;
  final Map<String, Object?> args;

  const AgentPendingAction(this.toolName, this.args);
}

/// Resultado da execução de uma tool.
class AgentToolOutcome {
  /// JSON enxuto devolvido ao modelo (nunca a lista completa).
  final Map<String, Object?> modelPayload;

  /// Cards/botões exibidos no chat (a lista completa vai aqui, não ao modelo).
  final List<ChatMessageEntity> messages;

  /// Escrita: interrompe o turno e mostra o card de confirmação.
  final AgentPendingAction? pending;
  final String? previewText;

  /// Handoff para o fluxo do menu (`'1'..'4'`).
  final String? menuOption;

  /// Navegação para a View (ex.: `open_budget|<id>`).
  final String? navigation;

  const AgentToolOutcome({
    this.modelPayload = const {},
    this.messages = const [],
    this.pending,
    this.previewText,
    this.menuOption,
    this.navigation,
  });
}

/// Resultado de um turno do agente para o ViewModel.
class AgentTurnResult {
  final String text;
  final List<ChatMessageEntity> messages;
  final String? menuOption;
  final String? navigation;
  final AgentPendingAction? pending;

  const AgentTurnResult({
    this.text = '',
    this.messages = const [],
    this.menuOption,
    this.navigation,
    this.pending,
  });
}

/// Limite diário de mensagens com IA atingido.
class AiDailyLimitException implements Exception {
  const AiDailyLimitException();
}
