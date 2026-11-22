import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_detail/budget_comment_detail_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_list/budget_comment_list_view_model.dart';
import 'package:oflite/modules/comment_library/domain/usecase/check_comment_library_access_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/improve_comment_text_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeRepo extends ChangeNotifier implements BudgetCommentRepository {
  _FakeRepo(this.items);

  List<ObservationBudget> items;
  ObservationBudget? updated;
  List<ObservationBudget>? deleted;

  @override
  Future<Result<List<ObservationBudget>>> fetchComments(
    String budgetId, {
    bool forceRefresh = false,
  }) async => Result.ok(items);

  @override
  Future<Result<void>> updateComment(String id, ObservationBudget c) async {
    updated = c;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deleteComments(String id, List<ObservationBudget> c) async {
    deleted = c;
    items = items.where((o) => !c.contains(o)).toList();
    return const Result.ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccess implements CheckCommentLibraryAccessUsecase {
  _FakeAccess(this.value);
  final bool value;

  @override
  bool call() => value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImprove implements ImproveCommentTextUsecase {
  @override
  Future<Result<String>> call(String text) async => const Result.ok('Melhorado');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ObservationBudget _obs(String id, String text) =>
    ObservationBudget(id: id, observacao: text, data: '22/11/2026');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeRepo repo;
  final a = _obs('a', 'Pagamento de 50% de entrada');
  final b = _obs('b', 'Garantia de 90 dias');

  Future<void> register({bool access = true}) async {
    await getIt.reset();
    repo = _FakeRepo([a, b]);
    getIt.registerSingleton<BudgetCommentRepository>(repo);
    getIt.registerSingleton<CheckCommentLibraryAccessUsecase>(_FakeAccess(access));
    getIt.registerSingleton<ImproveCommentTextUsecase>(_FakeImprove());
  }

  group('lista: seleção e remoção em massa', () {
    setUp(register);

    test('marcar, selecionar todos e remover', () async {
      final vm = BudgetCommentListViewModel(item: CustomerInfo()..id = 'b1');
      await vm.loadComments();
      expect(vm.selectionMode, isFalse);

      vm.markForDelete(a);
      vm.markForDelete(a);
      expect(vm.selectedCount, 1);

      vm.selectAll();
      expect(vm.allSelected, isTrue);
      vm.selectAll();
      expect(vm.selectionMode, isFalse);

      vm.toggleSelect(b);
      await vm.deleteCommand.execute();
      expect(repo.deleted, [b]);
      expect(vm.observation, [a]);
      expect(vm.selectionMode, isFalse);
    });
  });

  group('detalhe', () {
    test('abre em leitura; Editar libera; Melhorar só >10 e assinante', () async {
      await register();
      final vm = BudgetCommentDetailViewModel(budgetId: 'b1', comment: a);
      expect(vm.editing, isFalse);
      expect(vm.showImprove, isFalse);
      vm.startEditing();
      expect(vm.showImprove, isTrue);
      vm.textController.text = 'curto';
      expect(vm.showImprove, isFalse);
    });

    test('não assinante não vê Melhorar', () async {
      await register(access: false);
      final vm = BudgetCommentDetailViewModel(budgetId: 'b1', comment: a)
        ..startEditing();
      expect(vm.showImprove, isFalse);
    });

    test('salvar atualiza o texto mantendo id e data', () async {
      await register();
      final vm = BudgetCommentDetailViewModel(budgetId: 'b1', comment: a)
        ..startEditing();
      vm.textController.text = '  Novo texto  ';
      await vm.saveCommand.execute();
      expect(vm.saveCommand.completed, isTrue);
      expect(repo.updated!.id, 'a');
      expect(repo.updated!.observacao, 'Novo texto');
      expect(repo.updated!.data, '22/11/2026');
    });

    test('texto vazio vira erro inline sem gravar', () async {
      await register();
      final vm = BudgetCommentDetailViewModel(budgetId: 'b1', comment: a)
        ..startEditing();
      vm.textController.text = '  ';
      await vm.saveCommand.execute();
      expect(vm.emptyError, isTrue);
      expect(repo.updated, isNull);
    });

    test('cancelar volta ao texto original', () async {
      await register();
      final vm = BudgetCommentDetailViewModel(budgetId: 'b1', comment: a)
        ..startEditing();
      await vm.improveCommand.execute();
      expect(vm.textController.text, 'Melhorado');
      vm.cancelEditing();
      expect(vm.editing, isFalse);
      expect(vm.textController.text, a.observacao);
      expect(vm.canUndo, isFalse);
    });
  });
}
