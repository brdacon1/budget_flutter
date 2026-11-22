import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/update_pdf_field_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/document_validation_result.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/format_document_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/validate_document_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Valida o input de um campo PDF, salva e envia mensagens de confirmação.
class HandlePdfFieldInputUsecase {
  final UpdatePdfFieldUsecase _updatePdfField;
  final ChatBudgetRepository _chatRepo;
  final ValidateDocumentUsecase _validateDocument;
  final FormatDocumentUsecase _formatDocument;

  HandlePdfFieldInputUsecase(
    this._updatePdfField,
    this._chatRepo,
    this._validateDocument,
    this._formatDocument,
  );

  /// Valida CPF/CNPJ e devolve o valor mascarado, ou o erro.
  ({String? masked, DocumentType? type, DocumentValidationError? error})
  prepareDocument(String value) {
    final result = _validateDocument(value);
    if (!result.isValid) {
      return (masked: null, type: result.type, error: result.error);
    }
    return (
      masked: _formatDocument(result.cleaned!, result.type!),
      type: result.type,
      error: null,
    );
  }

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  Future<ChatMenuResult> call(String field, String value) async {
    switch (field) {
      case 'name':
        return await _save(
          'name',
          value,
          successMsg: '${ChatAssistantStrings.pdfEditSuccessName} $value',
        );
      case 'phone':
        final digits = value.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 10 || digits.length > 11) {
          await _chatRepo.sendMessage(
            ChatMessageEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              sender: ChatSender.bot,
              type: ChatMessageType.text,
              content: ChatAssistantStrings.pdfEditInvalidPhone,
              timestamp: DateTime.now(),
            ),
          );
          return const ChatMenuResult('pdfEditFieldInput', pdfField: 'phone');
        }
        final formatted = _phoneMask.maskText(digits);
        return await _save(
          'phone',
          formatted,
          successMsg: '${ChatAssistantStrings.pdfEditSuccessPhone} $formatted',
        );
      case 'email':
        if (!value.contains('@') || !value.contains('.')) {
          await _chatRepo.sendMessage(
            ChatMessageEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              sender: ChatSender.bot,
              type: ChatMessageType.text,
              content: ChatAssistantStrings.pdfEditInvalidEmail,
              timestamp: DateTime.now(),
            ),
          );
          return const ChatMenuResult('pdfEditFieldInput', pdfField: 'email');
        }
        return await _save(
          'email',
          value,
          successMsg: '${ChatAssistantStrings.pdfEditSuccessEmail} $value',
        );
      case 'cnpj':
        final doc = prepareDocument(value);
        if (doc.error != null) {
          await _chatRepo.sendMessage(
            ChatMessageEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              sender: ChatSender.bot,
              type: ChatMessageType.text,
              content: ChatAssistantStrings.documentError(doc.error!),
              timestamp: DateTime.now(),
            ),
          );
          return const ChatMenuResult('pdfEditDocumentForm', pdfField: 'cnpj');
        }
        return await _save(
          'cnpj',
          doc.masked!,
          successMsg:
              '${ChatAssistantStrings.pdfEditSuccessDocument(doc.type!)} ${doc.masked}',
        );
      default:
        return const ChatMenuResult('pdfEditFieldInput');
    }
  }

  Future<ChatMenuResult> _save(
    String field,
    String value, {
    required String successMsg,
  }) async {
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
        payload: {'highlight': value},
        timestamp: DateTime.now(),
      ),
    );

    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: ChatAssistantStrings.pdfEditNextQuestion,
        labels: ChatAssistantStrings.pdfEditNextOptionLabels,
        step: 'pdfEditConfirm',
      ),
    );

    return const ChatMenuResult('pdfEditConfirm');
  }
}
