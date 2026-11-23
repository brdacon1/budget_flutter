import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/dispatch_agent_tool_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Processa uma mensagem livre do usuário com a IA (loop de function calling).
///
/// 1. Envia histórico + tools ao modelo.
/// 2. Pediu tools → executa via [DispatchAgentToolUsecase], devolve o
///    resultado ao modelo e repete (máx. [_maxIterations]).
/// 3. Para quando o modelo responde texto, quando uma escrita precisa de
///    confirmação, ou num handoff/navegação.
class RunAgentTurnUsecase {
  final ChatAiRepository _aiRepo;
  final UserRepository _userRepo;
  final DispatchAgentToolUsecase _dispatch;

  const RunAgentTurnUsecase(this._aiRepo, this._userRepo, this._dispatch);

  static const _maxIterations = 5;

  /// Mensagens com IA por usuário por dia (controle de custo).
  static const dailyLimit = 100;

  Future<Result<AgentTurnResult>> call(String userText, {DateTime? now}) async {
    final today = _isoDate(now ?? DateTime.now());
    final used = await _aiRepo.usageOf(today);
    if (used >= dailyLimit) {
      return const Result.error(AiDailyLimitException());
    }
    await _aiRepo.saveUsage(today, used + 1);

    _aiRepo.addMessage(AgentMessageEntity(AgentRole.user, userText));
    final system = ChatAssistantStrings.aiSystemPrompt(
      today: today,
      userName: _userRepo.selectUser.value?.name ?? '',
    );
    final cards = <ChatMessageEntity>[];

    for (var i = 0; i < _maxIterations; i++) {
      final result = await _aiRepo.send(system, tools: _dispatch.tools);
      if (result case Error(:final error)) return Result.error(error);
      final reply = (result as Ok<AgentReplyEntity>).value;

      if (reply.toolCalls.isEmpty) {
        final text = reply.text.trim();
        if (text.isEmpty && cards.isEmpty) {
          return Result.error(Exception('empty_ai_response'));
        }
        if (text.isNotEmpty) {
          _aiRepo.addMessage(AgentMessageEntity(AgentRole.model, text));
        }
        return Result.ok(AgentTurnResult(text: text, messages: cards));
      }

      _aiRepo.addMessage(AgentMessageEntity.toolCall(reply.rawParts));
      for (final call in reply.toolCalls) {
        final outcome = await _dispatch(call);
        _aiRepo.addMessage(
          AgentMessageEntity.toolResult(call.name, outcome.modelPayload),
        );
        cards.addAll(outcome.messages);

        // Escrita, handoff e navegação encerram o turno sem nova chamada ao
        // modelo. Registra um texto do modelo para o histórico ficar válido.
        if (outcome.pending != null ||
            outcome.menuOption != null ||
            outcome.navigation != null) {
          _aiRepo.addMessage(
            AgentMessageEntity(
              AgentRole.model,
              outcome.previewText ?? '[${call.name}: ${call.args}]',
            ),
          );
          return Result.ok(
            AgentTurnResult(
              text: outcome.previewText ?? '',
              messages: cards,
              pending: outcome.pending,
              menuOption: outcome.menuOption,
              navigation: outcome.navigation,
            ),
          );
        }
      }
    }
    return Result.error(Exception('agent_max_iterations'));
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
