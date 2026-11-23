import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/budget_creator_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_draft_notifier.dart';

class _FakeRepo extends ChangeNotifier implements BudgetRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CustomerInfo _newItem() => CustomerInfo(id: '', customerName: '', status: '');

void main() {
  late BudgetDraftNotifier draft;

  setUp(() {
    draft = BudgetDraftNotifier();
    GetIt.I.registerSingleton<BudgetRepository>(_FakeRepo());
    GetIt.I.registerSingleton<BudgetDraftNotifier>(draft);
  });
  tearDown(GetIt.I.reset);

  testWidgets('orçamento novo publica o rascunho e atualiza ao digitar', (
    tester,
  ) async {
    final vm = BudgetCreatorViewModel(item: _newItem())..init();
    await tester.pump();
    expect(draft.value, isNotNull);
    expect(draft.value!.customerName, '');

    vm.nameController.text = 'Maria';
    expect(draft.value!.customerName, 'Maria');

    vm.nameController.text = 'Maria Silva';
    expect(draft.value!.customerName, 'Maria Silva');
  });

  testWidgets('sair sem salvar limpa o rascunho', (tester) async {
    final vm = BudgetCreatorViewModel(item: _newItem())..init();
    await tester.pump();
    expect(draft.value, isNotNull);

    vm.dispose();
    await tester.pump();
    expect(draft.value, isNull);
  });

  testWidgets('orçamento existente não gera rascunho', (tester) async {
    final vm = BudgetCreatorViewModel(
      item: CustomerInfo(id: '123', customerName: 'Ana', status: 'PENDENTE'),
    )..init();
    await tester.pump();
    vm.nameController.text = 'Ana Maria';
    expect(draft.value, isNull);
  });

  testWidgets('um formulário novo não apaga o rascunho de outro', (
    tester,
  ) async {
    final first = BudgetCreatorViewModel(item: _newItem())..init();
    await tester.pump();
    final second = BudgetCreatorViewModel(item: _newItem())..init();
    await tester.pump();
    second.nameController.text = 'Novo';

    first.dispose();
    await tester.pump();
    expect(draft.value?.customerName, 'Novo');
  });
}
