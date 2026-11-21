import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Opção "Relatórios": pede ao usuário a pergunta em linguagem livre, com um
/// exemplo. A resposta digitada segue para a IA (o step continua `mainMenu`).
class ShowReportsPromptUsecase {
  final ChatBudgetRepository _chatRepo;

  const ShowReportsPromptUsecase(this._chatRepo);

  Future<String> call() async {
    final now = DateTime.now();
    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: now.millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content:
            '${ChatAssistantStrings.reportsPrompt}\n\n'
            '${ChatAssistantStrings.reportsExample}',
        payload: {'highlight': ChatAssistantStrings.reportsExample},
        timestamp: now,
      ),
    );
    return 'mainMenu';
  }
}
