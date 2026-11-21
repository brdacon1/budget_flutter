import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Configura o submenu "Editar PDF" no chat.
///
/// Envia mensagem de texto com opções em botões.
class ShowPdfEditMenuUsecase {
  final ChatBudgetRepository _chatRepo;

  const ShowPdfEditMenuUsecase(this._chatRepo);

  /// Exibe o submenu de edição de PDF.
  Future<String> call() async {
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: ChatAssistantStrings.pdfEditMenuQuestion,
        labels: ChatAssistantStrings.pdfEditMenuOptionLabels,
        step: 'pdfEditMenu',
        backLabel: ChatAssistantStrings.menuBackLabel,
      ),
    );

    return 'pdfEditMenu';
  }
}
