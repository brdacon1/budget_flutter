import 'package:flutter/foundation.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/chat_ai_remote_datasource.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class ChatAiRepositoryImpl implements ChatAiRepository {
  final ChatAiRemoteDatasource _remote;

  ChatAiRepositoryImpl(this._remote);

  /// Janela de contexto: mantém o custo por turno constante.
  static const _maxHistory = 20;

  final List<AgentMessageEntity> _history = [];

  @override
  List<AgentMessageEntity> get history => List.unmodifiable(_history);

  @override
  void addMessage(AgentMessageEntity message) {
    _history.add(message);
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  @override
  void clearHistory() => _history.clear();

  @override
  Future<Result<AgentReplyEntity>> send(
    String system, {
    List<AgentToolSpec> tools = const [],
  }) async {
    try {
      final raw = await _remote.send(
        system: system,
        history: [
          for (final m in _history) {'role': m.role.name, 'text': m.text},
        ],
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
}
