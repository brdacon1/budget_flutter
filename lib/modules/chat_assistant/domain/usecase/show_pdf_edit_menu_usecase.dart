import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';

/// Configura o submenu "Editar PDF" no chat.
///
/// Envia mensagem de texto com opções numeradas.
class ShowPdfEditMenuUsecase {
  final ChatBudgetRepository _chatRepo;

  const ShowPdfEditMenuUsecase(this._chatRepo);

  /// Exibe o submenu de edição de PDF.
  Future<String> call() async {
    final content = '${ChatBudgetStrings.pdfEditMenuQuestion}\n\n'
        '${ChatBudgetStrings.pdfEditMenuOptions}\n\n'
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

    return 'pdfEditMenu';
  }
}
