import 'package:flutter/foundation.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/chat_ai_local_datasource.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/chat_ai_remote_datasource.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class ChatAiRepositoryImpl implements ChatAiRepository {
  final ChatAiRemoteDatasource _remote;
  final ChatAiLocalDatasource _local;

  ChatAiRepositoryImpl(this._remote, this._local);

  /// Janela de contexto: mantém o custo por turno constante.
  static const _maxHistory = 20;

  final List<AgentMessageEntity> _history = [];

  @override
  List<AgentMessageEntity> get history => List.unmodifiable(_history);

  @override
  void addMessage(AgentMessageEntity message) {
    _history.add(message);
    if (_history.length <= _maxHistory) return;
    _history.removeRange(0, _history.length - _maxHistory);
    // O histórico precisa começar numa mensagem de texto do usuário — nunca
    // numa chamada/resposta de tool órfã.
    while (_history.isNotEmpty &&
        !(_history.first.role == AgentRole.user &&
            _history.first.text.isNotEmpty)) {
      _history.removeAt(0);
    }
  }

  @override
  void clearHistory() => _history.clear();

  @override
  Future<int> usageOf(String day) => _local.usageOf(day);

  @override
  Future<void> saveUsage(String day, int count) => _local.saveUsage(day, count);

  @override
  Future<Result<AgentReplyEntity>> send(
    String system, {
    List<AgentToolSpec> tools = const [],
  }) async {
    try {
      final raw = await _remote.send(
        system: system,
        history: [for (final m in _history) _toMap(m)],
        tools: [
          for (final t in tools)
            {'name': t.name, 'description': t.description, 'params': t.params},
        ],
      );
      debugPrint(
        '[ChatAI] tokens in=${raw['inputTokens']} out=${raw['outputTokens']}',
      );
      return Result.ok(
        AgentReplyEntity(
          text: raw['text'] as String,
          toolCalls: [
            for (final c in raw['functionCalls'] as List)
              AgentToolCallEntity(
                c['name'] as String,
                (c['args'] as Map).cast<String, Object?>(),
              ),
          ],
          rawParts: (raw['parts'] as List).cast<Map<String, Object?>>(),
        ),
      );
    } on Exception catch (e) {
      debugPrint('[ChatAI] erro: $e');
      return Result.error(e);
    } catch (e) {
      debugPrint('[ChatAI] erro: $e');
      return Result.error(Exception(e.toString()));
    }
  }

  Map<String, Object?> _toMap(AgentMessageEntity m) => switch (m.role) {
    AgentRole.tool => {
      'role': 'tool',
      'name': m.toolName,
      'response': m.toolResponse,
    },
    AgentRole.model when m.rawParts.isNotEmpty => {
      'role': 'model',
      'parts': m.rawParts,
    },
    _ => {'role': m.role.name, 'text': m.text},
  };
}
