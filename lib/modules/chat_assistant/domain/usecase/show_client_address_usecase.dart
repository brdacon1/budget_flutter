import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_go_to_client_prompt_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// "Ir no cliente": mostra o endereço do orçamento escolhido com o botão
/// "Abrir no mapa". Sem endereço cadastrado, avisa e oferece escolher outro.
/// Toda mensagem tem "Voltar ao menu".
class ShowClientAddressUsecase {
  /// Ação que abre o mapa do endereço: `open_client_map|{budgetId}`.
  static const openMapAction = 'open_client_map|';

  final ChatBudgetRepository _chatRepo;

  const ShowClientAddressUsecase(this._chatRepo);

  Future<void> call(CustomerInfo budget) async {
    final name = budget.customerName?.trim() ?? '';
    final address = budget.fullAddress;
    final hasAddress = budget.hasAddress && address.isNotEmpty;
    final now = DateTime.now();
    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: '${now.microsecondsSinceEpoch}',
        sender: ChatSender.bot,
        type: ChatMessageType.action,
        content:
            hasAddress
                ? ChatAssistantStrings.goToClientAddress(name, address)
                : ChatAssistantStrings.goToClientNoAddress(name),
        payload: {
          'label':
              hasAddress
                  ? ChatAssistantStrings.goToClientOpenMapLabel
                  : ChatAssistantStrings.goToClientSelectAnotherLabel,
          'action':
              hasAddress
                  ? '$openMapAction${budget.id}'
                  : ShowGoToClientPromptUsecase.selectBudgetAction,
          'backLabel': ChatAssistantStrings.menuBackLabel,
        },
        timestamp: now,
      ),
    );
  }
}
