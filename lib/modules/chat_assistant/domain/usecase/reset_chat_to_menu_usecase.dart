import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Reseta o estado do chat e restaura o menu principal como ponto de entrada.
///
/// Envia a mensagem de menu no estilo bot do WhatsApp (opções em botões).
class ResetChatToMenuUsecase {
  final ChatBudgetRepository _chatRepo;

  const ResetChatToMenuUsecase(this._chatRepo);

  /// Executa o reset completo e retorna o nome do step a ser definido.
  /// [clearSession] false mantém a conversa e só reenvia o menu.
  /// [withReports] acrescenta as opções de IA "Relatórios" e "Encontrar
  /// orçamentos" e "Cadastrar comentários" (só no modo IA — recursos pagos).
  Future<String> call({
    bool clearSession = true,
    bool withReports = false,
  }) async {
    if (clearSession) _chatRepo.clearSession();
    _chatRepo.setCurrentFlowStep(null);

    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: ChatAssistantStrings.mainMenuQuestion,
        labels: [
          ...ChatAssistantStrings.mainMenuOptionLabels,
          if (withReports) ...[
            ChatAssistantStrings.reportsOptionLabel,
            ChatAssistantStrings.findBudgetOptionLabel,
            ChatAssistantStrings.commentLibraryOptionLabel,
          ],
        ],
        step: 'mainMenu',
      ),
    );

    return 'mainMenu';
  }
}
