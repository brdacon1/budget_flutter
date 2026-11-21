import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Opção "Encontrar orçamentos" (só modo IA): pede o nome do cliente, digitado
/// ou escolhido nos contatos (mesmo botão do "Criar orçamentos").
class ShowFindBudgetPromptUsecase {
  final ChatBudgetRepository _chatRepo;

  const ShowFindBudgetPromptUsecase(this._chatRepo);

  Future<String> call() async {
    final now = DateTime.now();
    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: now.millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.contactPicker,
        content: ChatAssistantStrings.findBudgetPrompt,
        timestamp: now,
      ),
    );
    return 'findBudgetAskName';
  }
}
