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

const _veryLong =
    'Descrição bem longa do item que precisa quebrar em duas linhas e ainda '
    'passar disso para cortar com reticências no final do texto';

Future<List<double>> _heights(
  WidgetTester tester,
  List<ItemsBudget> items, {
  double width = 360,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++)
                    BudgetListItemsCard(
                      key: ValueKey(i),
                      item: items[i],
                      selected: false,
                      selectionMode: false,
                      moneyConvert: _FakeMoney(),
                      onTap: () {},
                      onToggleSelect: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return [
    for (var i = 0; i < items.length; i++)
      tester.getSize(find.byKey(ValueKey(i))).height,
  ];
}

ItemsBudget _item({
  String description = 'Curto',
  String measure = 'un',
  double quantity = 1,
  double price = 10,
  double total = 10,
  String category = 'PRODUTOS',
}) => ItemsBudget(
  description: description,
  category: category,
  measure: measure,
  quantity: quantity,
  price: price,
  total: total,
);

void main() {
  final variations = [
    _item(),
    _item(description: _veryLong),
    _item(description: 'Duas linhas aproximadamente neste texto do item aqui'),
    _item(measure: 'unidade de medida muito comprida', quantity: 1234567),
    _item(price: 99999999.99, total: 123456789.99),
    _item(category: 'SERVICOS', description: _veryLong, total: 987654321),
  ];

  for (final scale in [1.0, 1.3]) {
    for (final width in [260.0, 360.0, 480.0]) {
      testWidgets('mesma altura (largura $width, texto x$scale)', (
        tester,
      ) async {
        final heights = await _heights(
          tester,
          variations,
          width: width,
          textScale: scale,
        );
        expect(heights.toSet().length, 1, reason: 'alturas: $heights');
      });
    }
  }
}
