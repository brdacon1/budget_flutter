import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_logo_in_chat_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';

/// Processa a opção escolhida no submenu "Logo".
class HandleLogoMenuOptionUsecase {
  final ChatBudgetRepository _chatRepo;
  final ShowLogoInChatUsecase _showLogoInChat;

  const HandleLogoMenuOptionUsecase(this._chatRepo, this._showLogoInChat);

  Future<ChatMenuResult> call(String option) async {
    switch (option) {
      case '1':
        await _showLogoInChat();
        return const ChatMenuResult('logoMenu');
      case '2':
        await _chatRepo.sendMessage(
          ChatMessageEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatSender.bot,
            type: ChatMessageType.text,
            content: 'Vou abrir a tela de edição de logo para você.',
            timestamp: DateTime.now(),
          ),
        );
        return const ChatMenuResult('logoMenu', navigation: 'open_logo_edit');
      case '0':
        return const ChatMenuResult('mainMenu');
      default:
        await _chatRepo.sendMessage(
          ChatMessageEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatSender.bot,
            type: ChatMessageType.text,
            content: ChatBudgetStrings.menuInvalidOption,
            timestamp: DateTime.now(),
          ),
        );
        return const ChatMenuResult('logoMenu');
    }
  }
}
