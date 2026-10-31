import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart';

/// Configura o submenu "Lista de preço" no chat.
///
/// Envia mensagem de texto com opções numeradas.
class ShowPriceListMenuUsecase {
  final ChatBudgetRepository _chatRepo;

  const ShowPriceListMenuUsecase(this._chatRepo);

  /// Exibe o submenu de lista de preço.
  Future<String> call() async {
    final content = '${ChatBudgetStrings.priceListMenuQuestion}\n\n'
        '${ChatBudgetStrings.priceListMenuOptions}\n\n'
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

    return 'priceListMenu';
  }
}
