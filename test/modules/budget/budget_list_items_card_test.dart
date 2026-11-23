import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/presenter/budget_list_items/components/budget_list_items_card.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';

class _FakeMoney implements ConvertCoinRepository {
  @override
  String convertFromDouble(double value) => 'R\$ $value';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('cards têm a mesma altura com descrição curta ou longa', (
    tester,
  ) async {
    ItemsBudget item(String description) => ItemsBudget(
      description: description,
      category: 'PRODUTOS',
      quantity: 1,
      price: 10,
      total: 10,
    );

    Widget card(Key key, String description) => BudgetListItemsCard(
      key: key,
      item: item(description),
      selected: false,
      moneyConvert: _FakeMoney(),
      onTap: () {},
      onToggleSelect: () {},
    );

    const shortKey = Key('short');
    const longKey = Key('long');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: Column(
              children: [
                card(shortKey, 'Curto'),
                card(
                  longKey,
                  'Descrição bem longa do item que precisa quebrar em duas '
                  'linhas e ainda passar disso para cortar com reticências',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(shortKey)).height,
      tester.getSize(find.byKey(longKey)).height,
    );
  });
}
