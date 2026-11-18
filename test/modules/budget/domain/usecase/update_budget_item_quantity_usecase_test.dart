import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/update_budget_item_quantity_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class FakeBudgetRepository extends ChangeNotifier implements BudgetRepository {
  String? savedBudgetId;
  ItemsBudget? savedItem;
  Result<void> saveResult = const Result.ok(null);

  @override
  Future<Result<void>> saveBudgetItem(String budgetId, ItemsBudget item) async {
    savedBudgetId = budgetId;
    savedItem = item;
    return saveResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeBudgetRepository repo;
  late UpdateBudgetItemQuantityUsecase usecase;

  final item = ItemsBudget(
    id: 'item-1',
    category: 'Produtos',
    description: 'Calça jeans',
    price: 120,
    quantity: 15,
    measure: 'unidade',
    total: 1800,
    idProduct: 'prod-1',
  )..indice = 3;

  setUp(() {
    repo = FakeBudgetRepository();
    usecase = UpdateBudgetItemQuantityUsecase(repo);
  });

  test('recalcula total = quantidade × preço e grava no mesmo id', () async {
    final result = await usecase(budgetId: 'b-1', item: item, quantity: 10);

    expect(result, isA<Ok<void>>());
    expect(repo.savedBudgetId, 'b-1');
    final saved = repo.savedItem!;
    expect(saved.id, 'item-1');
    expect(saved.quantity, 10);
    expect(saved.total, 1200);
    expect(saved.price, 120);
    expect(saved.category, 'Produtos');
    expect(saved.description, 'Calça jeans');
    expect(saved.measure, 'unidade');
    expect(saved.idProduct, 'prod-1');
    expect(saved.indice, 3);
  });

  test('aceita quantidade decimal', () async {
    await usecase(budgetId: 'b-1', item: item, quantity: 2.5);
    expect(repo.savedItem!.total, 300);
  });

  test('não altera o item original', () async {
    await usecase(budgetId: 'b-1', item: item, quantity: 10);
    expect(item.quantity, 15);
    expect(item.total, 1800);
  });

  test('quantidade <= 0 retorna erro sem gravar', () async {
    final zero = await usecase(budgetId: 'b-1', item: item, quantity: 0);
    final negative = await usecase(budgetId: 'b-1', item: item, quantity: -1);

    expect(zero, isA<Error<void>>());
    expect(negative, isA<Error<void>>());
    expect(repo.savedItem, isNull);
  });

  test('item sem id retorna erro sem gravar', () async {
    final result = await usecase(
      budgetId: 'b-1',
      item: ItemsBudget(price: 10, quantity: 1),
      quantity: 2,
    );

    expect(result, isA<Error<void>>());
    expect(repo.savedItem, isNull);
  });

  test('propaga erro do repositório', () async {
    repo.saveResult = Result.error(Exception('offline'));
    final result = await usecase(budgetId: 'b-1', item: item, quantity: 10);
    expect(result, isA<Error<void>>());
  });
}
