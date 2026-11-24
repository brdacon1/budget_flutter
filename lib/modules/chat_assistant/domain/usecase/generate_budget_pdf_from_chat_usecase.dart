import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Prepara a abertura do PDF do orçamento criado no chat.
///
/// Seleciona o rascunho finalizado (a tela de PDF lê `selectBudget`).
class GenerateBudgetPdfFromChatUsecase {
  final ChatBudgetRepository _chatRepo;
  final BudgetRepository _budgetRepo;
  const GenerateBudgetPdfFromChatUsecase(this._chatRepo, this._budgetRepo);

  Future<Result<void>> call() async {
    final budget = _chatRepo.draftBudget;
    if (budget == null || (budget.id ?? '').isEmpty) {
      return Result.error(Exception('Orçamento não disponível'));
    }
    _budgetRepo.selectBudget.value = budget;
    return const Result.ok(null);
  }
}
