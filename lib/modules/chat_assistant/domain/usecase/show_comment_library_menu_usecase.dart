import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Submenu "Cadastrar comentários" no chat (só assinantes / modo IA).
class ShowCommentLibraryMenuUsecase {
  final ChatBudgetRepository _chatRepo;

  const ShowCommentLibraryMenuUsecase(this._chatRepo);

  static const step = 'commentLibraryMenu';

  Future<String> call() async {
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: ChatAssistantStrings.commentLibraryMenuQuestion,
        labels: ChatAssistantStrings.commentLibraryMenuOptionLabels,
        step: step,
        backLabel: ChatAssistantStrings.menuBackLabel,
      ),
    );
    return step;
  }
}
