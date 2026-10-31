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

    final dataRows = <Map<String, String>>[];

    dataRows.add(_row(
      '🏢 Nome da empresa:',
      owner?.empresa?.trim().isNotEmpty == true ? owner!.empresa!.trim() : 'Não cadastrado',
    ));
    dataRows.add(_row(
      '📞 Telefone:',
      owner?.fone?.trim().isNotEmpty == true ? owner!.fone!.trim() : 'Não cadastrado',
    ));
    dataRows.add(_row(
      '📧 Email:',
      owner?.email?.trim().isNotEmpty == true ? owner!.email!.trim() : 'Não cadastrado',
    ));
    dataRows.add(_row(
      '🏛️ CNPJ:',
      owner?.cnpj?.trim().isNotEmpty == true ? owner!.cnpj!.trim() : 'Não cadastrado',
    ));

    final addressParts = <String>[];
    if (owner?.rua?.trim().isNotEmpty == true) addressParts.add(owner!.rua!.trim());
    if (owner?.bairro?.trim().isNotEmpty == true) addressParts.add(owner!.bairro!.trim());
    if (owner?.city?.trim().isNotEmpty == true) addressParts.add(owner!.city!.trim());
    if (owner?.cep?.trim().isNotEmpty == true) addressParts.add('CEP: ${owner!.cep!.trim()}');
    dataRows.add(_row(
      '📍 Endereço:',
      addressParts.isNotEmpty ? addressParts.join(' - ') : 'Não cadastrado',
    ));

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.inlineButtons,
        content: ChatBudgetStrings.pdfEditProceedQuestion,
        payload: {
          'actions': ['Sim', 'Não'],
          'dataRows': dataRows,
        },
        timestamp: DateTime.now(),
      ),
    );
    return 'pdfEditConfirmEntry';
  }

  Map<String, String> _row(String label, String value) {
    return {'label': label, 'value': value};
  }
}
