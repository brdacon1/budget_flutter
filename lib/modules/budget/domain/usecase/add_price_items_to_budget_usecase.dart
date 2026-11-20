import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Adiciona ao orçamento os itens escolhidos na lista de preço.
///
/// Regra de negócio: toda quantidade deve ser maior que zero e
/// `total = quantidade × preço unitário`. Cada item é gravado com o mesmo id
/// do produto da lista de preço (comportamento de sempre).
class AddPriceItemsToBudgetUsecase {
  final BudgetRepository _budgetRepo;

  const AddPriceItemsToBudgetUsecase(this._budgetRepo);

  Future<Result<void>> call({
    required String budgetId,
    required List<ItemsBudget> items,
  }) async {
    if (budgetId.isEmpty) return Result.error(Exception('Orçamento sem id'));
    if (items.isEmpty) return Result.error(Exception('Nenhum item'));
    if (items.any((i) => (i.quantity ?? 0) <= 0)) {
      return Result.error(Exception('Quantidade deve ser maior que zero'));
    }

    for (final item in items) {
      final result = await _budgetRepo.saveBudgetItem(
        budgetId,
        ItemsBudget(
          id: item.id,
          category: item.category,
          description: item.description,
          price: item.price,
          quantity: item.quantity,
          measure: item.measure,
          total: (item.quantity ?? 0) * (item.price ?? 0),
          idProduct: item.idProduct ?? item.id,
        ),
      );
      if (result is Error<void>) return result;
    }
    return const Result.ok(null);
  }
}
