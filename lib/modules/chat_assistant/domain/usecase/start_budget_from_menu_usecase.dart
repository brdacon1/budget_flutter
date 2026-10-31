import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_script_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_script_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';

/// Orquestra a transição do menu principal para o fluxo de orçamento.
///
/// Envia mensagem de transição + boas-vindas + solicitação do nome.
class StartBudgetFromMenuUsecase {
  final ChatBudgetRepository _chatRepo;
  final ChatScriptRepository _scriptRepo;

  const StartBudgetFromMenuUsecase(this._chatRepo, this._scriptRepo);

  /// Inicia o fluxo de orçamento a partir do menu principal.
  Future<String> call() async {
    final script = _scriptRepo.currentScript;

    // Mensagem de transição
    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content: ChatBudgetStrings.budgetTransition,
        timestamp: DateTime.now(),
      ),
    );

    // Pede nome com picker de contato
    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.contactPicker,
        content: script?.askClientName ??
            ChatScriptEntity.fallback.askClientName,
        timestamp: DateTime.now(),
      ),
    );

    return 'askClient';
  }
}
