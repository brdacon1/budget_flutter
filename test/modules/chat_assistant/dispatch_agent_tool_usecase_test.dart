import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/get_month_summary_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/update_budget_status_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/confirm_agent_action_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/dispatch_agent_tool_usecase.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/domain/usecase/create_receipt_for_budget_usecase.dart';
import 'package:oflite/modules/receipt/domain/usecase/list_receipts_by_budget_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeBudgetRepo extends ChangeNotifier implements BudgetRepository {
  _FakeBudgetRepo(this.all);

  final List<CustomerInfo> all;

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgets({
    bool forceRefresh = false,
  }) async => Result.ok(all);

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgetsByMonthRange(
    String startId,
    String endId,
  ) async => Result.ok(all);

  @override
  Future<Result<CustomerInfo>> getBudgetById(String id) async =>
      Result.ok(all.firstWhere((b) => b.id == id, orElse: CustomerInfo.new));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReceipts implements ListReceiptsByBudgetUsecase {
  @override
  Future<Result<List<ReceiptWithTotal>>> call(String budgetId) async =>
      Result.ok([
        (receipt: const Receipt(id: 'r1', descricao: 'Entrada'), paid: 40.0),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShare implements ShareLinkRepository {
  @override
  Future<String?> buildShareUrl({required String enderecoNumero}) async =>
      'https://link/$enderecoNumero';
}

class _FakeCoin implements ConvertCoinRepository {
  @override
  String convertFromDouble(double value) => 'R\$ ${value.toStringAsFixed(2)}';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCreateReceipt implements CreateReceiptForBudgetUsecase {
  Map<String, Object?>? got;

  @override
  Future<Result<Receipt>> call({
    required String budgetId,
    required String description,
    double? amount,
    String? method,
    DateTime? now,
  }) async {
    got = {'budgetId': budgetId, 'description': description, 'amount': amount};
    return const Result.ok(Receipt(id: 'r9'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUpdateStatus implements UpdateBudgetStatusUsecase {
  @override
  Future<Result<CustomerInfo>> call(String id, BudgetStatus s) async =>
      Result.error(Exception('offline'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAiRepo implements ChatAiRepository {
  final List<AgentMessageEntity> log = [];

  @override
  void addMessage(AgentMessageEntity message) => log.add(message);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final budgets = [
    for (var i = 0; i < 25; i++)
      CustomerInfo(
        id: '${1763000000000 + i}',
        customerName: 'Cliente $i',
        status: i.isEven ? 'PENDENTE' : 'APROVADO',
        totalValue: 10,
        data: '01/11/2026',
      ),
  ];

  late DispatchAgentToolUsecase dispatch;
  setUp(() {
    final repo = _FakeBudgetRepo(budgets);
    final list = ListBudgetsUsecase(repo);
    dispatch = DispatchAgentToolUsecase(
      list,
      GetMonthSummaryUsecase(list),
      _FakeReceipts(),
      repo,
      _FakeShare(),
      _FakeCoin(),
    );
  });

  Future<AgentToolOutcome> run(String name, Map<String, Object?> args) =>
      dispatch(AgentToolCallEntity(name, args));

  test(
    'list_budgets: modelo recebe no máx. 20 itens, UI recebe todos',
    () async {
      final out = await run('list_budgets', {'status': 'PENDENTE'});
      expect(out.modelPayload['count'], 13);
      expect(out.modelPayload['total'], 'R\$ 130.00');
      expect((out.modelPayload['items'] as List).length, 13);

      final all = await run('list_budgets', {});
      expect((all.modelPayload['items'] as List).length, 20);
      final card = all.messages.single;
      expect(card.type, ChatMessageType.budgetList);
      expect((card.payload!['items'] as List).length, 25);
    },
  );

  test(
    'argumentos inválidos viram {error} para o modelo se corrigir',
    () async {
      expect((await run('list_budgets', {'status': 'pago'})).modelPayload, {
        'error': 'invalid_status',
      });
      expect(
        (await run('list_budgets', {
          'from': '18/11/2026',
        })).modelPayload['error'],
        'date must be yyyy-MM-dd',
      );
      expect(
        (await run('get_month_summary', {
          'month': '11/2026',
        })).modelPayload['error'],
        'month must be yyyy-MM',
      );
      expect(
        (await run('create_receipt', {
          'budget_id': 'x',
          'description': 'a',
        })).modelPayload['error'],
        'budget_not_found',
      );
      expect(
        (await run('delete_all', {})).modelPayload['error'],
        'unknown_tool',
      );
    },
  );

  test('get_month_summary devolve card com totais do usecase', () async {
    final out = await run('get_month_summary', {'month': '2026-11'});
    expect(out.modelPayload['count'], 25);
    expect(out.messages.single.type, ChatMessageType.summaryCard);
  });

  test('create_receipt só prepara a ação (não grava)', () async {
    final id = budgets.first.id!;
    final out = await run('create_receipt', {
      'budget_id': id,
      'description': 'Entrada',
      'amount': 500,
      'method': 'PIX',
    });
    expect(out.pending?.toolName, 'create_receipt');
    expect(out.pending?.args['amount'], 500.0);
    expect(out.previewText, contains('Cliente 0'));
    expect(out.modelPayload['status'], 'awaiting_user_confirmation');
  });

  test('list_receipts e get_budget_link', () async {
    final id = budgets.first.id!;
    final r = await run('list_receipts', {'budget_id': id});
    expect(r.modelPayload['total_recebido'], 'R\$ 40.00');
    expect(r.modelPayload['saldo'], 'R\$ -30.00');

    final l = await run('get_budget_link', {'budget_id': id});
    expect(l.messages.single.payload!['action'], 'share_url|https://link/$id');
  });

  group('ConfirmAgentActionUsecase', () {
    test('confirmado grava; falha e cancelamento não', () async {
      final ai = _FakeAiRepo();
      final create = _FakeCreateReceipt();
      final confirm = ConfirmAgentActionUsecase(
        ai,
        create,
        _FakeUpdateStatus(),
      );

      final ok = await confirm(
        const AgentPendingAction('create_receipt', {
          'budget_id': 'b1',
          'client': 'João',
          'description': 'Entrada',
          'amount': 500.0,
        }),
        confirmed: true,
      );
      expect(ok, contains('João'));
      expect(create.got?['amount'], 500.0);

      final failed = await confirm(
        const AgentPendingAction('update_budget_status', {
          'budget_id': 'b1',
          'status': 'APROVADO',
        }),
        confirmed: true,
      );
      expect(failed, isNot(contains('✅')));

      create.got = null;
      await confirm(
        const AgentPendingAction('create_receipt', {'budget_id': 'b1'}),
        confirmed: false,
      );
      expect(create.got, isNull);
      // Desfecho registrado em pares user/model para o histórico seguir válido.
      expect(ai.log.length, 6);
    });
  });
}
