import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Configura o submenu "Lista de preço" no chat.
///
/// Envia mensagem de texto com opções em botões.
class ShowPriceListMenuUsecase {
  final ChatBudgetRepository _chatRepo;

  const ShowPriceListMenuUsecase(this._chatRepo);

  /// Exibe o submenu de lista de preço.
  Future<String> call() async {
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: ChatAssistantStrings.priceListMenuQuestion,
        labels: ChatAssistantStrings.priceListMenuOptionLabels,
        step: 'priceListMenu',
        backLabel: ChatAssistantStrings.menuBackLabel,
      ),
    );

    return 'priceListMenu';
  }
}
