import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';

/// Configura o submenu "Trocar nome de usuário" no chat.
///
/// Envia mensagem de texto com opções numeradas.
class ShowChangeUsernameMenuUsecase {
  final ChatBudgetRepository _chatRepo;
  final UserRepository _userRepository;

  const ShowChangeUsernameMenuUsecase(this._chatRepo, this._userRepository);

  /// Exibe o submenu de alteração de nome de usuário.
  Future<String> call() async {
    final currentName = _userRepository.selectUser.value?.NOME?.trim() ?? '';
    final content = currentName.isNotEmpty
        ? 'O nome de usuário atual é "$currentName".\n\n'
            '${ChatBudgetStrings.changeUsernameMenuOptions}\n\n'
            '${ChatBudgetStrings.menuBackOption}'
        : '${ChatBudgetStrings.changeUsernameInstructions}\n\n'
            '${ChatBudgetStrings.changeUsernameMenuOptions}\n\n'
            '${ChatBudgetStrings.menuBackOption}';

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content: content,
        payload: {'showMenuHint': true},
        timestamp: DateTime.now(),
      ),
    );

    return 'changeUsername';
  }
}
