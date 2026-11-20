import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Prepara a abertura do PDF do orçamento criado no chat.
///
/// Seleciona o rascunho finalizado (a tela de PDF lê `selectBudget`) e,
/// para não assinantes, aguarda o intersticial ser fechado antes de seguir.
class GenerateBudgetPdfFromChatUsecase {
  final ChatBudgetRepository _chatRepo;
  final BudgetRepository _budgetRepo;
  final AdsRepository _ads;

  const GenerateBudgetPdfFromChatUsecase(
    this._chatRepo,
    this._budgetRepo,
    this._ads,
  );

  Future<Result<void>> call() async {
    final budget = _chatRepo.draftBudget;
    if (budget == null || (budget.id ?? '').isEmpty) {
      return Result.error(Exception('Orçamento não disponível'));
    }
    _budgetRepo.selectBudget.value = budget;
    if (_ads.shouldShowAds) await _ads.showInterstitialAndWait();
    return Result.ok(null);
  }
}
