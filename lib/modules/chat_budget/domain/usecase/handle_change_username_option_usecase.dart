import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart';

/// Processa a opção escolhida no submenu "Trocar nome de usuário".
class HandleChangeUsernameOptionUsecase {
  final ChatBudgetRepository _chatRepo;

  const HandleChangeUsernameOptionUsecase(this._chatRepo);

  Future<ChatMenuResult> call(String option) async {
    switch (option) {
      case '1':
        await _chatRepo.sendMessage(
          ChatMessageEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatSender.bot,
            type: ChatMessageType.text,
            content: 'Vou abrir o modal para você.',
            timestamp: DateTime.now(),
          ),
        );
        return const ChatMenuResult('changeUsername', navigation: 'open_change_name');
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
        return const ChatMenuResult('changeUsername');
    }
  }
}
