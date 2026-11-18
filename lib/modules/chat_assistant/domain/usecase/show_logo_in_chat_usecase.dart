import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Exibe a logo da empresa no chat (mensagem tipo image).
///
/// A URL vem do [PdfRepository] — quem conhece o Storage é o DataSource.
class ShowLogoInChatUsecase {
  final PdfRepository _pdfRepo;
  final ChatBudgetRepository _chatRepo;

  const ShowLogoInChatUsecase(this._pdfRepo, this._chatRepo);

  Future<bool> call() async {
    final result = await _pdfRepo.fetchInformationEnterprise();
    if (result is Error<OwnerPdf>) return false;

    final imageUrl = _pdfRepo.logoUrl((result as Ok<OwnerPdf>).value);
    final now = DateTime.now();

    if (imageUrl == null) {
      await _chatRepo.sendMessage(
        ChatMessageEntity(
          id: now.millisecondsSinceEpoch.toString(),
          sender: ChatSender.bot,
          type: ChatMessageType.text,
          content: ChatBudgetStrings.logoNotFound,
          timestamp: now,
        ),
      );
      return false;
    }

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: now.millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.image,
        content: ChatBudgetStrings.logoCaption,
        payload: {
          'imageUrl': imageUrl,
          'changeAction': 'open_logo_edit',
          'changeLabel': ChatBudgetStrings.logoChangeLabel,
        },
        timestamp: now,
      ),
    );
    return true;
  }
}
