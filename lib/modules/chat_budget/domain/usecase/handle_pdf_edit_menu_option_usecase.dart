import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart';

/// Processa a opção escolhida no submenu "Editar PDF".
class HandlePdfEditMenuOptionUsecase {
  final ChatBudgetRepository _chatRepo;

  const HandlePdfEditMenuOptionUsecase(this._chatRepo);

  Future<ChatMenuResult> call(String option) async {
    switch (option) {
      case '1':
        await _sendTextWithBackOption(ChatBudgetStrings.pdfEditAskName);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'name');
      case '2':
        await _sendTextWithBackOption(ChatBudgetStrings.pdfEditAskPhone);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'phone');
      case '3':
        await _sendTextWithBackOption(ChatBudgetStrings.pdfEditAskEmail);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'email');
      case '4':
        await _sendTextWithBackOption(ChatBudgetStrings.pdfEditAskCnpj);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'cnpj');
      case '5':
        await _chatRepo.sendMessage(
          ChatMessageEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatSender.bot,
            type: ChatMessageType.text,
            content:
                '${ChatBudgetStrings.pdfEditAskHasCep}\n\n1. Sim\n2. Não\n\n${ChatBudgetStrings.menuBackOption}',
            timestamp: DateTime.now(),
          ),
        );
        return const ChatMenuResult('askHasCep');
      case '6':
        await _chatRepo.sendMessage(
          ChatMessageEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatSender.bot,
            type: ChatMessageType.text,
            content:
                '${ChatBudgetStrings.logoMenuQuestion}\n\n${ChatBudgetStrings.logoMenuOptions}',
            timestamp: DateTime.now(),
          ),
        );
        return const ChatMenuResult('logoMenu');
      case '0':
        return const ChatMenuResult('mainMenu');
      default:
        return const ChatMenuResult('pdfEditMenu');
    }
  }

  Future<void> _sendTextWithBackOption(String text) async {
    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content: '$text\n\n${ChatBudgetStrings.menuBackOption}',
        timestamp: DateTime.now(),
      ),
    );
  }
}
