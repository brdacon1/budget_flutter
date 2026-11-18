import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/usecase/update_budget_status_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/dispatch_agent_tool_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/receipt/domain/usecase/create_receipt_for_budget_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Executa (ou cancela) a escrita que a IA preparou, após o toque do usuário.
/// Não chama o modelo — custo zero. Registra o desfecho no histórico para a
/// IA saber o que aconteceu se a conversa continuar.
class ConfirmAgentActionUsecase {
  final ChatAiRepository _aiRepo;
  final CreateReceiptForBudgetUsecase _createReceipt;
  final UpdateBudgetStatusUsecase _updateStatus;

  const ConfirmAgentActionUsecase(
    this._aiRepo,
    this._createReceipt,
    this._updateStatus,
  );

  /// Devolve o texto de feedback para o chat.
  Future<String> call(
    AgentPendingAction action, {
    required bool confirmed,
  }) async {
    if (!confirmed) {
      _log(action, 'cancelado pelo usuário');
      return ChatBudgetStrings.aiActionCancelled;
    }

    final args = action.args;
    final budgetId = args['budget_id'] as String;
    final client = args['client'] as String? ?? '';

    final String? done = switch (action.toolName) {
      DispatchAgentToolUsecase.createReceipt => switch (await _createReceipt(
        budgetId: budgetId,
        description: args['description'] as String,
        amount: args['amount'] as double?,
        method: args['method'] as String?,
      )) {
        Ok() => ChatBudgetStrings.aiReceiptCreated(client),
        Error() => null,
      },
      DispatchAgentToolUsecase.updateStatus => switch (await _updateStatus(
        budgetId,
        BudgetStatus.fromValue(args['status'] as String)!,
      )) {
        Ok() => ChatBudgetStrings.aiStatusUpdated(
          client,
          args['status'] as String,
        ),
        Error() => null,
      },
      _ => null,
    };

    _log(action, done == null ? 'falhou' : 'concluído');
    return done ?? ChatBudgetStrings.aiActionFailed;
  }

  void _log(AgentPendingAction action, String outcome) {
    _aiRepo.addMessage(
      AgentMessageEntity(AgentRole.user, '[${action.toolName}: $outcome]'),
    );
    _aiRepo.addMessage(AgentMessageEntity(AgentRole.model, 'Ok.'));
  }
}
