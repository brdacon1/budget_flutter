import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_filter.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/get_month_summary_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/update_budget_status_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeBudgetRepo extends ChangeNotifier implements BudgetRepository {
  _FakeBudgetRepo(this.all);

  final List<CustomerInfo> all;
  String? rangeStart;
  String? rangeEnd;
  CustomerInfo? updated;

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgets({
    bool forceRefresh = false,
  }) async => Result.ok(all);

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgetsByMonthRange(
    String startId,
    String endId,
  ) async {
    rangeStart = startId;
    rangeEnd = endId;
    return Result.ok([
      for (final b in all)
        if (b.id!.compareTo(startId) >= 0 && b.id!.compareTo(endId) <= 0) b,
    ]);
  }

  @override
  Future<Result<CustomerInfo>> getBudgetById(String id) async =>
      Result.ok(all.firstWhere((b) => b.id == id, orElse: CustomerInfo.new));

  @override
  Future<Result<void>> updateBudget(CustomerInfo budget) async {
    updated = budget;
    return const Result.ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CustomerInfo _b(DateTime at, String name, String status, double value) =>
    CustomerInfo(
      id: at.millisecondsSinceEpoch.toString(),
      customerName: name,
      status: status,
      totalValue: value,
    );

void main() {
  final budgets = [
    _b(DateTime(2026, 10, 31, 23, 59), 'Ana Outubro', 'PENDENTE', 50),
    _b(DateTime(2026, 11, 1), 'João Silva', 'PENDENTE', 100),
    _b(DateTime(2026, 11, 15), 'Maria', 'APROVADO', 300),
    _b(DateTime(2026, 11, 30, 22), 'José Álvares', 'PENDENTE', 200),
    _b(DateTime(2026, 12, 1), 'Dezembro', 'APROVADO', 999),
  ];

  group('ListBudgetsUsecase', () {
    test('período inclui o último dia inteiro e filtra status', () async {
      final repo = _FakeBudgetRepo(budgets);
      final result = await ListBudgetsUsecase(repo)(
        BudgetFilter(
          status: BudgetStatus.pendente,
          from: DateTime(2026, 11, 1),
          to: DateTime(2026, 11, 30),
        ),
      );
      final names = (result as Ok<List<CustomerInfo>>).value.map(
        (b) => b.customerName,
      );
      // Ordenado do mais recente; 30/11 às 22h entra (bug do dashboard não).
      expect(names, ['José Álvares', 'João Silva']);
    });

    test('nome do cliente ignora acento e caixa', () async {
      final result = await ListBudgetsUsecase(_FakeBudgetRepo(budgets))(
        const BudgetFilter(clientName: 'jose alv'),
      );
      expect(
        (result as Ok<List<CustomerInfo>>).value.single.customerName,
        'José Álvares',
      );
    });
  });

  test('GetMonthSummaryUsecase agrupa por status só do mês', () async {
    final usecase = GetMonthSummaryUsecase(
      ListBudgetsUsecase(_FakeBudgetRepo(budgets)),
    );
    final s = ((await usecase(DateTime(2026, 11))) as Ok<MonthSummary>).value;
    expect(s.count, 3);
    expect(s.total, 600);
    expect(s.byStatus['PENDENTE'], (count: 2, total: 300.0));
    expect(s.byStatus['APROVADO'], (count: 1, total: 300.0));
    expect(s.byStatus['REPROVADO'], (count: 0, total: 0.0));
  });

  group('UpdateBudgetStatusUsecase', () {
    test('grava o valor persistido do status', () async {
      final repo = _FakeBudgetRepo(budgets);
      final id = budgets[1].id!;
      final result = await UpdateBudgetStatusUsecase(repo)(
        id,
        BudgetStatus.aprovado,
      );
      expect(result, isA<Ok<CustomerInfo>>());
      expect(repo.updated?.status, 'APROVADO');
    });

    test('orçamento inexistente não grava', () async {
      final repo = _FakeBudgetRepo(budgets);
      final result = await UpdateBudgetStatusUsecase(repo)(
        'nao-existe',
        BudgetStatus.aprovado,
      );
      expect(result, isA<Error<CustomerInfo>>());
      expect(repo.updated, isNull);
    });
  });
}
