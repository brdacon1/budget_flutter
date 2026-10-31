import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';

/// Envia confirmação após o usuário voltar da tela de edição de logo.
class OnLogoUpdatedUsecase {
  final ChatBudgetRepository _chatRepo;

  const OnLogoUpdatedUsecase(this._chatRepo);

  Future<String> call() async {
    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content: 'Logo atualizada com sucesso.',
        timestamp: DateTime.now(),
      ),
    );

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content:
            '${ChatBudgetStrings.pdfEditMenuQuestion}\n\n${ChatBudgetStrings.pdfEditMenuOptions}\n\n${ChatBudgetStrings.menuBackOption}',
        timestamp: DateTime.now(),
      ),
    );

    return 'pdfEditMenu';
  }
}
