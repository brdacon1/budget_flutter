import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart';

/// Processa a opção de confirmação após editar um campo PDF.
class HandlePdfEditConfirmOptionUsecase {
  final ChatBudgetRepository _chatRepo;

  const HandlePdfEditConfirmOptionUsecase(this._chatRepo);

  Future<ChatMenuResult> call(String option) async {
    switch (option) {
      case '1':
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
        return const ChatMenuResult('pdfEditMenu');
      case '2':
        return const ChatMenuResult('mainMenu');
      default:
        return const ChatMenuResult('pdfEditConfirm');
    }
  }
}
