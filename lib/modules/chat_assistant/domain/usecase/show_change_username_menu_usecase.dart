import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';

/// Configura o submenu "Trocar nome de usuário" no chat.
///
/// Envia mensagem de texto com opções em botões.
class ShowChangeUsernameMenuUsecase {
  final ChatBudgetRepository _chatRepo;
  final UserRepository _userRepository;

  const ShowChangeUsernameMenuUsecase(this._chatRepo, this._userRepository);

  /// Exibe o submenu de alteração de nome de usuário.
  Future<String> call() async {
    final currentName = _userRepository.selectUser.value?.name?.trim() ?? '';
    final content =
        currentName.isNotEmpty
            ? 'O nome de usuário atual é "$currentName".'
            : ChatAssistantStrings.changeUsernameInstructions;

    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: content,
        labels: ChatAssistantStrings.changeUsernameMenuOptionLabels,
        step: 'changeUsername',
        backLabel: ChatAssistantStrings.menuBackLabel,
      ),
    );

    return 'changeUsername';
  }
}
