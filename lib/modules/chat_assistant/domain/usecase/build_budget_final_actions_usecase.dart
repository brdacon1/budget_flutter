import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';

/// Define os botões do card final do fluxo de criar orçamento.
///
/// Assinante: copiar link + gerar PDF. Não assinante: só gerar PDF
/// (com intersticial antes — ver [GenerateBudgetPdfFromChatUsecase]).
class BuildBudgetFinalActionsUsecase {
  final AdsRepository _ads;

  const BuildBudgetFinalActionsUsecase(this._ads);

  List<String> call() =>
      _ads.shouldShowAds
          ? [ChatBudgetStrings.generatePdfLabel]
          : [
            ChatBudgetStrings.copyLinkLabel,
            ChatBudgetStrings.generatePdfLabel,
          ];
}
