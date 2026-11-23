import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Opção "Ir no cliente" (só modo IA): pede o orçamento com o botão que abre
/// o modal de seleção e "Voltar ao menu". Devolve a navegação para já abrir
/// o modal.
class ShowGoToClientPromptUsecase {
  /// Ação/navegação que abre o modal de orçamentos para ir ao cliente.
  static const selectBudgetAction = 'go_to_client_select_budget';

  final ChatBudgetRepository _chatRepo;

  const ShowGoToClientPromptUsecase(this._chatRepo);

  Future<String> call() async {
    final now = DateTime.now();
    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: '${now.microsecondsSinceEpoch}',
        sender: ChatSender.bot,
        type: ChatMessageType.action,
        content: ChatAssistantStrings.goToClientPrompt,
        payload: {
          'label': ChatAssistantStrings.aiSelectBudgetLabel,
          'action': selectBudgetAction,
          'backLabel': ChatAssistantStrings.menuBackLabel,
        },
        timestamp: now,
      ),
    );
    return selectBudgetAction;
  }
}
