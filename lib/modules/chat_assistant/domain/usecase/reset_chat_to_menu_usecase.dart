import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/start_budget_from_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reseta o estado do chat e restaura o menu principal como ponto de entrada.
///
/// Envia a mensagem de menu no estilo bot do WhatsApp (opções em botões).
class ResetChatToMenuUsecase {
  final ChatBudgetRepository _chatRepo;

  const ResetChatToMenuUsecase(this._chatRepo);

  /// Executa o reset completo e retorna o nome do step a ser definido.
  /// [clearSession] false mantém a conversa e só reenvia o menu.
  /// [withReports] acrescenta as opções de IA "Relatórios" e "Encontrar
  /// orçamentos", "Cadastrar comentários" e "Ir no cliente" (só no modo IA — recursos pagos).
  ///
  /// [trialMenu] (teste grátis): só as 4 opções principais — criar orçamentos,
  /// produtos, editar PDF e comentários. Quem assina vê o menu completo.
  Future<String> call({
    bool clearSession = true,
    bool withReports = false,
    bool trialMenu = false,
  }) async {
    if (clearSession) _chatRepo.clearSession();
    _chatRepo.setCurrentFlowStep(null);

    // Até começar o 1º orçamento, o menu convida a criá-lo (ativação).
    final prefs = await SharedPreferences.getInstance();
    final firstTime =
        !(prefs.getBool(StartBudgetFromMenuUsecase.startedPrefKey) ?? false);

    // Modo IA (assinante/teste): sem botões — balão animado e o usuário digita.
    if (withReports) {
      for (final m in ChatMessageEntity.aiIntro(
        question:
            firstTime
                ? ChatAssistantStrings.firstBudgetMenuQuestion
                : ChatAssistantStrings.mainMenuQuestion,
        examples: ChatAssistantStrings.aiExamples(trial: trialMenu),
      )) {
        await _chatRepo.sendMessage(m);
      }
      return 'mainMenu';
    }

    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content:
            firstTime
                ? ChatAssistantStrings.firstBudgetMenuQuestion
                : ChatAssistantStrings.mainMenuQuestion,
        labels:
            trialMenu
                ? [
                  ChatAssistantStrings.mainMenuOptionLabels[0],
                  ChatAssistantStrings.mainMenuOptionLabels[1],
                  ChatAssistantStrings.mainMenuOptionLabels[2],
                  ChatAssistantStrings.commentLibraryOptionLabel,
                ]
                : [
                  ...ChatAssistantStrings.mainMenuOptionLabels,
                  if (withReports) ...[
                    ChatAssistantStrings.reportsOptionLabel,
                    ChatAssistantStrings.findBudgetOptionLabel,
                    ChatAssistantStrings.commentLibraryOptionLabel,
                    ChatAssistantStrings.goToClientOptionLabel,
                  ],
                ],
        // Valores fixos: no teste, "Comentários" é o 4º botão com valor 7.
        values: trialMenu ? const ['1', '2', '3', '7'] : null,
        step: 'mainMenu',
      ),
    );

    return 'mainMenu';
  }
}
