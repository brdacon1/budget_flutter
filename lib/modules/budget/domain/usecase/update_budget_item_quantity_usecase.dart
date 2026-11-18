import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Argumento do `Command1` que atualiza a quantidade de um item (§4.4 regra 6).
typedef BudgetItemQuantityUpdate = ({ItemsBudget item, double quantity});

/// Atualiza a quantidade de um item do orçamento.
///
/// Regra de negócio: `total = quantidade × preço unitário`. Grava o item no
/// mesmo `id` (as chaves persistidas `QTD`/`TOTAL` não mudam). O total do
/// orçamento é recalculado por quem recarrega a lista de itens.
class UpdateBudgetItemQuantityUsecase {
  final BudgetRepository _budgetRepo;

  const UpdateBudgetItemQuantityUsecase(this._budgetRepo);

  Future<Result<void>> call({
    required String budgetId,
    required ItemsBudget item,
    required double quantity,
  }) async {
    if (quantity <= 0) {
      return Result.error(Exception('Quantidade deve ser maior que zero'));
    }
    if (item.id == null || item.id!.isEmpty) {
      return Result.error(Exception('Item sem id'));
    }

    final updated = ItemsBudget(
      id: item.id,
      category: item.category,
      description: item.description,
      price: item.price,
      quantity: quantity,
      measure: item.measure,
      total: quantity * (item.price ?? 0),
      idProduct: item.idProduct,
      checkBox: item.checkBox,
      selectProduct: item.selectProduct,
    )..indice = item.indice;

    return _budgetRepo.saveBudgetItem(budgetId, updated);
  }
}
