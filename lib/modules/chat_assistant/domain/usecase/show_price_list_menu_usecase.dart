import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';

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
        content: ChatBudgetStrings.priceListMenuQuestion,
        labels: ChatBudgetStrings.priceListMenuOptionLabels,
        step: 'priceListMenu',
        backLabel: ChatBudgetStrings.menuBackLabel,
      ),
    );

    return 'priceListMenu';
  }
}
