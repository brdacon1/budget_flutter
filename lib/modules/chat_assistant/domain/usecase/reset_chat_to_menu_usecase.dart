import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';

/// Reseta o estado do chat e restaura o menu principal como ponto de entrada.
///
/// Envia a mensagem de menu no estilo bot do WhatsApp (opções em botões).
class ResetChatToMenuUsecase {
  final ChatBudgetRepository _chatRepo;

  const ResetChatToMenuUsecase(this._chatRepo);

  /// Executa o reset completo e retorna o nome do step a ser definido.
  /// [clearSession] false mantém a conversa e só reenvia o menu.
  /// [withReports] acrescenta a opção "Relatórios" (só no modo IA — sem a IA
  /// não há como responder perguntas livres).
  Future<String> call({
    bool clearSession = true,
    bool withReports = false,
  }) async {
    if (clearSession) _chatRepo.clearSession();
    _chatRepo.setCurrentFlowStep(null);

    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: ChatBudgetStrings.mainMenuQuestion,
        labels: [
          ...ChatBudgetStrings.mainMenuOptionLabels,
          if (withReports) ChatBudgetStrings.reportsOptionLabel,
        ],
        step: 'mainMenu',
      ),
    );

    return 'mainMenu';
  }
}
