import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Processa a opção escolhida no submenu "Editar PDF".
class HandlePdfEditMenuOptionUsecase {
  final ChatBudgetRepository _chatRepo;
  final PdfRepository _pdfRepo;

  const HandlePdfEditMenuOptionUsecase(this._chatRepo, this._pdfRepo);

  Future<ChatMenuResult> call(String option) async {
    OwnerPdf? owner;
    final pdfResult = await _pdfRepo.fetchInformationEnterprise();
    if (pdfResult is Ok<OwnerPdf>) {
      owner = pdfResult.value;
    }

    switch (option) {
      case '1':
        final current = owner?.empresa?.trim() ?? '';
        final msg =
            current.isNotEmpty
                ? 'O nome da empresa atual é "$current".\n${ChatAssistantStrings.pdfEditAskName}'
                : ChatAssistantStrings.pdfEditAskName;
        await _sendTextWithBackOption(msg, highlight: current);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'name');
      case '2':
        final current = owner?.fone?.trim() ?? '';
        final msg =
            current.isNotEmpty
                ? 'O telefone atual é "$current".\n${ChatAssistantStrings.pdfEditAskPhone}'
                : ChatAssistantStrings.pdfEditAskPhone;
        await _sendTextWithBackOption(msg, highlight: current);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'phone');
      case '3':
        final current = owner?.email?.trim() ?? '';
        final msg =
            current.isNotEmpty
                ? 'O email atual é "$current".\n${ChatAssistantStrings.pdfEditAskEmail}'
                : ChatAssistantStrings.pdfEditAskEmail;
        await _sendTextWithBackOption(msg, highlight: current);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'email');
      case '4':
        final current = owner?.cnpj?.trim() ?? '';
        final msg =
            current.isNotEmpty
                ? 'O CNPJ atual é "$current".\n${ChatAssistantStrings.pdfEditAskCnpj}'
                : ChatAssistantStrings.pdfEditAskCnpj;
        await _sendTextWithBackOption(msg, highlight: current);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'cnpj');
      case '5':
        await _chatRepo.sendMessage(
          ChatMessageEntity.botOptions(
            content: ChatAssistantStrings.pdfEditAskHasCep,
            labels: ChatAssistantStrings.yesNoOptionLabels,
            step: 'askHasCep',
            backLabel: ChatAssistantStrings.menuBackLabel,
          ),
        );
        return const ChatMenuResult('askHasCep');
      case '6':
        await _chatRepo.sendMessage(
          ChatMessageEntity.botOptions(
            content: ChatAssistantStrings.logoMenuQuestion,
            labels: ChatAssistantStrings.logoMenuOptionLabels,
            step: 'logoMenu',
            backLabel: ChatAssistantStrings.menuBackLabel,
          ),
        );
        return const ChatMenuResult('logoMenu');
      case '7':
        return const ChatMenuResult(
          'pdfEditMenu',
          navigation: 'open_pdf_model_select',
        );
      case '0':
        return const ChatMenuResult('mainMenu');
      default:
        return const ChatMenuResult('pdfEditMenu');
    }
  }

  Future<void> _sendTextWithBackOption(String text, {String? highlight}) async {
    await _chatRepo.sendMessage(
      ChatMessageEntity.botOptions(
        content: text,
        labels: const [],
        step: 'pdfEditFieldInput',
        backLabel: ChatAssistantStrings.menuBackLabel,
        highlight: highlight,
      ),
    );
  }
}
