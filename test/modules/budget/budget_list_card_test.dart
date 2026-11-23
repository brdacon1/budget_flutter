import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/card/budget_list_card.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/common/constants/colors.dart';

class _FakeMoney implements ConvertCoinRepository {
  @override
  String convertFromDouble(double value) => 'R\$ $value';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, BudgetListCard card) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));

BudgetListCard _card(
  CustomerInfo item, {
  bool draft = false,
  bool active = false,
}) => BudgetListCard(
  item: item,
  selected: false,
  active: active,
  draft: draft,
  moneyConvert: _FakeMoney(),
  onTap: null,
  onMore: null,
);

void main() {
  testWidgets('rascunho sem nome mostra "Novo orçamento" e a etiqueta', (
    tester,
  ) async {
    await _pump(
      tester,
      _card(
        CustomerInfo(id: '', customerName: '', status: 'PENDENTE'),
        draft: true,
      ),
    );
    expect(find.text(BudgetStrings.newBudget), findsOneWidget);
    expect(find.text(BudgetStrings.draftLabel), findsOneWidget);
  });

  testWidgets('rascunho com nome mostra o que foi digitado', (tester) async {
    await _pump(
      tester,
      _card(
        CustomerInfo(id: '', customerName: 'Maria', status: 'PENDENTE'),
        draft: true,
      ),
    );
    expect(find.text('Maria'), findsOneWidget);
    expect(find.text(BudgetStrings.newBudget), findsNothing);
  });

  testWidgets('card aberto tem o fundo ciano do item selecionado', (
    tester,
  ) async {
    await _pump(
      tester,
      _card(
        CustomerInfo(id: '1', customerName: 'Ana', status: 'PENDENTE'),
        active: true,
      ),
    );
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(BudgetListCard),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, buttonColor.withValues(alpha: 0.15));
  });
}
