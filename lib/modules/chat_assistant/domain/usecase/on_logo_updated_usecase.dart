import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_logo_in_chat_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Envia confirmação após o usuário voltar da tela de edição de logo.
class OnLogoUpdatedUsecase {
  final ChatBudgetRepository _chatRepo;
  final PdfRepository _pdfRepo;
  final ShowLogoInChatUsecase _showLogoInChat;

  const OnLogoUpdatedUsecase(
    this._chatRepo,
    this._pdfRepo,
    this._showLogoInChat,
  );

  Future<String> call() async {
    // Busca a logo atualizada para simular uma "foto enviada" pelo usuário
    final result = await _pdfRepo.fetchInformationEnterprise();
    if (result is Ok<OwnerPdf>) {
      final owner = result.value;
      final hasLogo = owner.fotoId != null && owner.fotoId!.isNotEmpty;
      if (hasLogo) {
        final String fotoId = owner.fotoId ?? '';
        final imageUrl = fotoId.startsWith('http')
            ? fotoId
            : 'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/'
              '${Uri.encodeComponent(owner.logoName ?? '')}?alt=media&token=$fotoId';

        // Mostra a logo como se o usuário tivesse enviado uma foto (estilo WhatsApp)
        await _chatRepo.sendMessage(
          ChatMessageEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatSender.user,
            type: ChatMessageType.image,
            content: '',
            payload: {'imageUrl': imageUrl},
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content: 'Logo atualizada com sucesso.',
        timestamp: DateTime.now(),
      ),
    );

    // Mostra a logo novamente no chat com botão de alterar
    await _showLogoInChat();

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content:
            '${ChatBudgetStrings.pdfEditMenuQuestion}\n\n${ChatBudgetStrings.pdfEditMenuOptions}\n\n${ChatBudgetStrings.menuBackOption}',
        payload: {'showMenuHint': true},
        timestamp: DateTime.now(),
      ),
    );

    return 'pdfEditMenu';
  }
}
