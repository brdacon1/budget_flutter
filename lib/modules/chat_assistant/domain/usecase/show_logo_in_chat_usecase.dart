import 'package:http/http.dart' as http;
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Exibe a logo da empresa no chat (mensagem tipo image).
class ShowLogoInChatUsecase {
  final PdfRepository _pdfRepo;
  final ChatBudgetRepository _chatRepo;

  const ShowLogoInChatUsecase(this._pdfRepo, this._chatRepo);

  Future<bool> call() async {
    final result = await _pdfRepo.fetchInformationEnterprise();
    if (result is Error<OwnerPdf>) return false;

    final owner = (result as Ok<OwnerPdf>).value;
    final hasLogo = owner.fotoId != null &&
        owner.fotoId!.isNotEmpty &&
        owner.logoName != null &&
        owner.logoName!.isNotEmpty;

    if (!hasLogo) {
      await _chatRepo.sendMessage(
        ChatMessageEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: ChatSender.bot,
          type: ChatMessageType.text,
          content: 'Você ainda não tem uma logo cadastrada.',
          timestamp: DateTime.now(),
        ),
      );
      return false;
    }

    // Verificar se a logo está acessível
    final imageUrl =
        'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/'
        '${Uri.encodeComponent(owner.logoName!)}?alt=media&token=${owner.fotoId}';

    // Tenta baixar para garantir que a URL é válida
    try {
      final response = await http.head(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        await _chatRepo.sendMessage(
          ChatMessageEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatSender.bot,
            type: ChatMessageType.text,
            content: 'Você ainda não tem uma logo cadastrada.',
            timestamp: DateTime.now(),
          ),
        );
        return false;
      }
    } catch (_) {
      // Se falhar, tenta mostrar mesmo assim
    }

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.image,
        content: 'Logo da sua empresa:',
        payload: {
          'imageUrl': imageUrl,
          'changeAction': 'open_logo_edit',
          'changeLabel': 'Alterar logo',
        },
        timestamp: DateTime.now(),
      ),
    );
    return true;
  }
}
