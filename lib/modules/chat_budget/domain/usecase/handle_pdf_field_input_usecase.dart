import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/update_pdf_field_usecase.dart';
import 'package:oflite/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Valida o input de um campo PDF, salva e envia mensagens de confirmação.
class HandlePdfFieldInputUsecase {
  final UpdatePdfFieldUsecase _updatePdfField;
  final ChatBudgetRepository _chatRepo;

  HandlePdfFieldInputUsecase(this._updatePdfField, this._chatRepo);

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  Future<ChatMenuResult> call(String field, String value) async {
    switch (field) {
      case 'name':
        return await _save('name', value,
            successMsg: '${ChatBudgetStrings.pdfEditSuccessName} $value');
      case 'phone':
        final digits = value.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 10 || digits.length > 11) {
          await _chatRepo.sendMessage(
            ChatMessageEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              sender: ChatSender.bot,
              type: ChatMessageType.text,
              content: ChatBudgetStrings.pdfEditInvalidPhone,
              timestamp: DateTime.now(),
            ),
          );
          return const ChatMenuResult('pdfEditFieldInput', pdfField: 'phone');
        }
        final formatted = _phoneMask.maskText(digits);
        return await _save('phone', formatted,
            successMsg: '${ChatBudgetStrings.pdfEditSuccessPhone} $formatted');
      case 'email':
        if (!value.contains('@') || !value.contains('.')) {
          await _chatRepo.sendMessage(
            ChatMessageEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              sender: ChatSender.bot,
              type: ChatMessageType.text,
              content: ChatBudgetStrings.pdfEditInvalidEmail,
              timestamp: DateTime.now(),
            ),
          );
          return const ChatMenuResult('pdfEditFieldInput', pdfField: 'email');
        }
        return await _save('email', value,
            successMsg: '${ChatBudgetStrings.pdfEditSuccessEmail} $value');
      case 'cnpj':
        final digits = value.replaceAll(RegExp(r'\D'), '');
        if (digits.length != 14) {
          await _chatRepo.sendMessage(
            ChatMessageEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              sender: ChatSender.bot,
              type: ChatMessageType.text,
              content: ChatBudgetStrings.pdfEditInvalidCnpj,
              timestamp: DateTime.now(),
            ),
          );
          return const ChatMenuResult('pdfEditFieldInput', pdfField: 'cnpj');
        }
        final masked =
            '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12, 14)}';
        return await _save('cnpj', masked,
            successMsg: '${ChatBudgetStrings.pdfEditSuccessCnpj} $masked');
      default:
        return const ChatMenuResult('pdfEditFieldInput');
    }
  }

  Future<ChatMenuResult> _save(String field, String value,
      {required String successMsg}) async {
    final result = await _updatePdfField(field, value);

    if (result is Error<OwnerPdf>) {
      await _chatRepo.sendMessage(
        ChatMessageEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: ChatSender.bot,
          type: ChatMessageType.text,
          content: 'Erro ao salvar: ${result.error}',
          timestamp: DateTime.now(),
        ),
      );
      return const ChatMenuResult('pdfEditMenu');
    }

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content: successMsg,
        timestamp: DateTime.now(),
      ),
    );

    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content:
            'O que você quer fazer agora?\n\n1. Continuar editando PDF\n2. Voltar ao menu principal',
        timestamp: DateTime.now(),
      ),
    );

    return const ChatMenuResult('pdfEditConfirm');
  }
}
