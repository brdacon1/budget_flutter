import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';

/// Define os botões do card final do fluxo de criar orçamento.
///
/// Acesso total (assinante/teste): copiar link + gerar PDF. Expirado: só PDF.
class BuildBudgetFinalActionsUsecase {
  final GetAccessStatusUseCase _access;

  const BuildBudgetFinalActionsUsecase(this._access);

  List<String> call() =>
      _access.hasFullAccess
          ? [
            ChatAssistantStrings.copyLinkLabel,
            ChatAssistantStrings.generatePdfLabel,
          ]
          : [ChatAssistantStrings.generatePdfLabel];
}
