import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart';

/// Configura o submenu "Trocar nome de usuário" no chat.
///
/// Envia mensagem de texto com opções numeradas.
class ShowChangeUsernameMenuUsecase {
  final ChatBudgetRepository _chatRepo;

  const ShowChangeUsernameMenuUsecase(this._chatRepo);

  /// Exibe o submenu de alteração de nome de usuário.
  Future<String> call() async {
    final content = '${ChatBudgetStrings.changeUsernameInstructions}\n\n'
        '${ChatBudgetStrings.changeUsernameMenuOptions}\n\n'
        '${ChatBudgetStrings.menuBackOption}';

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content: content,
        timestamp: DateTime.now(),
      ),
    );

    return 'changeUsername';
  }
}
