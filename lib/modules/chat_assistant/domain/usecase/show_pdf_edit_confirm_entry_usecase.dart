import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Antes de entrar no submenu "Editar PDF", mostra todos os dados
/// cadastrados e pergunta se o usuário deseja prosseguir.
class ShowPdfEditConfirmEntryUsecase {
  final ChatBudgetRepository _chatRepo;
  final PdfRepository _pdfRepo;

  const ShowPdfEditConfirmEntryUsecase(this._chatRepo, this._pdfRepo);

  Future<String> call() async {
    OwnerPdf? owner;
    final result = await _pdfRepo.fetchInformationEnterprise();
    if (result is Ok<OwnerPdf>) {
      owner = result.value;
    }

    final buffer = StringBuffer();
    buffer.writeln('📋 *Dados cadastrados do PDF:*');
    buffer.writeln();
    buffer.writeln('🏢 Nome da empresa: ${owner?.empresa?.trim().isNotEmpty == true ? owner!.empresa!.trim() : "—"}');
    buffer.writeln('📞 Telefone: ${owner?.fone?.trim().isNotEmpty == true ? owner!.fone!.trim() : "—"}');
    buffer.writeln('📧 Email: ${owner?.email?.trim().isNotEmpty == true ? owner!.email!.trim() : "—"}');
    buffer.writeln('🏛️ CNPJ: ${owner?.cnpj?.trim().isNotEmpty == true ? owner!.cnpj!.trim() : "—"}');
    final addressParts = <String>[];
    if (owner?.rua?.trim().isNotEmpty == true) addressParts.add(owner!.rua!.trim());
    if (owner?.bairro?.trim().isNotEmpty == true) addressParts.add(owner!.bairro!.trim());
    if (owner?.city?.trim().isNotEmpty == true) addressParts.add(owner!.city!.trim());
    if (owner?.cep?.trim().isNotEmpty == true) addressParts.add('CEP: ${owner!.cep!.trim()}');
    if (addressParts.isNotEmpty) {
      buffer.writeln('📍 Endereço: ${addressParts.join(' - ')}');
    } else {
      buffer.writeln('📍 Endereço: —');
    }
    buffer.writeln('🖼️ Logo: ${owner?.logoName?.trim().isNotEmpty == true ? 'cadastrada' : "—"}');
    buffer.writeln();
    buffer.writeln( ChatBudgetStrings.pdfEditProceedQuestion );

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.inlineButtons,
        content: buffer.toString(),
        payload: {'actions': ['Sim', 'Não']},
        timestamp: DateTime.now(),
      ),
    );
    return 'pdfEditConfirmEntry';
  }
}
