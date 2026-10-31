import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
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
        final msg = current.isNotEmpty
            ? 'O nome da empresa atual é "$current".\n${ChatBudgetStrings.pdfEditAskName}'
            : ChatBudgetStrings.pdfEditAskName;
        await _sendTextWithBackOption(msg);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'name');
      case '2':
        final current = owner?.fone?.trim() ?? '';
        final msg = current.isNotEmpty
            ? 'O telefone atual é "$current".\n${ChatBudgetStrings.pdfEditAskPhone}'
            : ChatBudgetStrings.pdfEditAskPhone;
        await _sendTextWithBackOption(msg);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'phone');
      case '3':
        final current = owner?.email?.trim() ?? '';
        final msg = current.isNotEmpty
            ? 'O email atual é "$current".\n${ChatBudgetStrings.pdfEditAskEmail}'
            : ChatBudgetStrings.pdfEditAskEmail;
        await _sendTextWithBackOption(msg);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'email');
      case '4':
        final current = owner?.cnpj?.trim() ?? '';
        final msg = current.isNotEmpty
            ? 'O CNPJ atual é "$current".\n${ChatBudgetStrings.pdfEditAskCnpj}'
            : ChatBudgetStrings.pdfEditAskCnpj;
        await _sendTextWithBackOption(msg);
        return const ChatMenuResult('pdfEditFieldInput', pdfField: 'cnpj');
      case '5':
        await _chatRepo.sendMessage(
          ChatMessageEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatSender.bot,
            type: ChatMessageType.text,
            content:
                '${ChatBudgetStrings.pdfEditAskHasCep}\n\n1. Sim\n2. Não\n\n${ChatBudgetStrings.menuBackOption}',
            timestamp: DateTime.now(),
          ),
        );
        return const ChatMenuResult('askHasCep');
      case '6':
        await _chatRepo.sendMessage(
          ChatMessageEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatSender.bot,
            type: ChatMessageType.text,
            content:
                '${ChatBudgetStrings.logoMenuQuestion}\n\n${ChatBudgetStrings.logoMenuOptions}',
            timestamp: DateTime.now(),
          ),
        );
        return const ChatMenuResult('logoMenu');
      case '0':
        return const ChatMenuResult('mainMenu');
      default:
        return const ChatMenuResult('pdfEditMenu');
    }
  }

  Future<void> _sendTextWithBackOption(String text) async {
    await _chatRepo.sendMessage(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.bot,
        type: ChatMessageType.text,
        content: '$text\n\n${ChatBudgetStrings.menuBackOption}',
        timestamp: DateTime.now(),
      ),
    );
  }
}
