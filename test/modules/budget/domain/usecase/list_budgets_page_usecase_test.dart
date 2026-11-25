import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_filter.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_page_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Repositório com [total] orçamentos (ID decrescente), todos PENDENTE, exceto
/// os índices em [approvedAt].
class _Repo extends ChangeNotifier implements BudgetRepository {
  _Repo(this.total, {this.approvedAt = const {}});

  final int total;
  final Set<int> approvedAt;
  int reads = 0;

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgetsPage({
    required int limit,
    String? startAfterId,
  }) async {
    reads++;
    final start = startAfterId == null ? 0 : int.parse(startAfterId) + 1;
    return Result.ok([
      for (var i = start; i < total && i < start + limit; i++)
        CustomerInfo()
          ..id = '$i'
          ..status = approvedAt.contains(i) ? 'APROVADO' : 'PENDENTE',
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('lê uma página por vez, sem carregar tudo', () async {
    final repo = _Repo(100);
    final uc = ListBudgetsPageUsecase(repo, ListBudgetsUsecase(repo));

    final r = await uc(const BudgetFilter());
    final page = (r as Ok).value;

    expect(page.items.length, ListBudgetsPageUsecase.pageSize);
    expect(page.hasMore, isTrue);
    expect(repo.reads, 1);

    final next = (await uc(const BudgetFilter(), cursor: page.cursor) as Ok)
        .value;
    expect(next.items.first.id, '20');
  });

  test('filtra status e continua lendo até completar a página', () async {
    final repo = _Repo(200, approvedAt: {5, 50, 150});
    final uc = ListBudgetsPageUsecase(repo, ListBudgetsUsecase(repo));

    final page =
        (await uc(const BudgetFilter(status: BudgetStatus.aprovado)) as Ok)
            .value;

    expect(page.items.map((b) => b.id), ['5', '50']);
    expect(page.hasMore, isTrue);
    expect(repo.reads, ListBudgetsPageUsecase.maxReadsPerCall);
  });

  test('última página termina com hasMore false', () async {
    final repo = _Repo(25);
    final uc = ListBudgetsPageUsecase(repo, ListBudgetsUsecase(repo));

    final first = (await uc(const BudgetFilter()) as Ok).value;
    final second =
        (await uc(const BudgetFilter(), cursor: first.cursor) as Ok).value;

    expect(second.items.length, 5);
    expect(second.hasMore, isFalse);
  });
}
