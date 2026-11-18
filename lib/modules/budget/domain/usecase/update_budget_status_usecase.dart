import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Altera o status de um orçamento existente (grava o valor persistido).
class UpdateBudgetStatusUsecase {
  final BudgetRepository _repo;

  const UpdateBudgetStatusUsecase(this._repo);

  Future<Result<CustomerInfo>> call(
    String budgetId,
    BudgetStatus status,
  ) async {
    final found = await _repo.getBudgetById(budgetId);
    if (found case Error(:final error)) return Result.error(error);

    final budget = (found as Ok<CustomerInfo>).value;
    if (budget.id == null) return Result.error(Exception('budget_not_found'));
    final updated = budget.copyWith(status: status.value);
    final saved = await _repo.updateBudget(updated);
    if (saved case Error(:final error)) return Result.error(error);
    return Result.ok(updated);
  }
}
