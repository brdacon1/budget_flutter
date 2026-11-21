import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_logo_in_chat_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Chamado quando o usuário volta da tela de edição de logo (ou da tela de
/// assinatura). Segue o mesmo caminho da opção "Ver logo": exibe a logo atual
/// (ou avisa que não há logo) e reapresenta o menu da logo para o usuário
/// continuar ou voltar ao início.
class OnLogoUpdatedUsecase {
  final ChatBudgetRepository _chatRepo;
  final ShowLogoInChatUsecase _showLogoInChat;

  const OnLogoUpdatedUsecase(this._chatRepo, this._showLogoInChat);

  Future<String> call() async {
    await _showLogoInChat();

    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: ChatAssistantStrings.logoMenuQuestion,
        labels: ChatAssistantStrings.logoMenuOptionLabels,
        step: 'logoMenu',
        backLabel: ChatAssistantStrings.menuBackLabel,
      ),
    );

    return 'logoMenu';
  }
}
