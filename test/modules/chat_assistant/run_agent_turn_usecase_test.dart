import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/check_ai_access_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/dispatch_agent_tool_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/run_agent_turn_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeUserRepo extends ChangeNotifier implements UserRepository {
  _FakeUserRepo(InfoUser? user) : selectUser = ValueNotifier(user);

  @override
  ValueNotifier<InfoUser?> selectUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Repo de IA roteirizado: devolve as respostas da fila, uma por chamada.
class _FakeAiRepo implements ChatAiRepository {
  _FakeAiRepo(this.replies);

  final List<Result<AgentReplyEntity>> replies;
  int sends = 0;
  String? lastSystem;
  int usage = 0;
  final List<AgentMessageEntity> _history = [];

  @override
  List<AgentMessageEntity> get history => _history;

  @override
  void addMessage(AgentMessageEntity message) => _history.add(message);

  @override
  void clearHistory() => _history.clear();

  @override
  Future<int> usageOf(String day) async => usage;

  @override
  Future<void> saveUsage(String day, int count) async => usage = count;

  @override
  Future<Result<AgentReplyEntity>> send(
    String system, {
    List<AgentToolSpec> tools = const [],
  }) async {
    lastSystem = system;
    return replies[sends++];
  }
}

class _FakeDispatch implements DispatchAgentToolUsecase {
  _FakeDispatch(this.outcomes);

  final Map<String, AgentToolOutcome> outcomes;
  final calls = <String>[];

  @override
  List<AgentToolSpec> get tools => const [];

  @override
  Future<AgentToolOutcome> call(AgentToolCallEntity call) async {
    calls.add(call.name);
    return outcomes[call.name]!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Result<AgentReplyEntity> _text(String t) =>
    Result.ok(AgentReplyEntity(text: t));

Result<AgentReplyEntity> _call(String name, [Map<String, Object?>? args]) =>
    Result.ok(
      AgentReplyEntity(
        toolCalls: [AgentToolCallEntity(name, args ?? const {})],
        rawParts: [
          {
            'functionCall': {'name': name},
            'thoughtSignature': 'sig',
          },
        ],
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final user = InfoUser()..name = 'David';

  group('CheckAiAccessUsecase', () {
    bool off() => false;

    test('assinante tem acesso', () {
      final u = InfoUser()..autoRenewing = true;
      expect(
        CheckAiAccessUsecase(_FakeUserRepo(u), forcePremium: off)(),
        isTrue,
      );
    });

    test('FORCE_PREMIUM libera mesmo sem pagamento', () {
      expect(
        CheckAiAccessUsecase(_FakeUserRepo(null), forcePremium: () => true)(),
        isTrue,
      );
    });

    test('trial ativo e sem sync (offline) têm acesso', () {
      final trial = InfoUser()..trialStartedAt = DateTime.now();
      expect(
        CheckAiAccessUsecase(_FakeUserRepo(trial), forcePremium: off)(),
        isTrue,
      );
      expect(
        CheckAiAccessUsecase(_FakeUserRepo(InfoUser()), forcePremium: off)(),
        isTrue,
      );
    });

    test('trial expirado não tem acesso', () {
      final expired =
          InfoUser()
            ..trialStartedAt = DateTime.now().subtract(const Duration(days: 3));
      expect(
        CheckAiAccessUsecase(_FakeUserRepo(expired), forcePremium: off)(),
        isFalse,
      );
    });
  });

  group('RunAgentTurnUsecase', () {
    RunAgentTurnUsecase build(_FakeAiRepo ai, _FakeDispatch d) =>
        RunAgentTurnUsecase(ai, _FakeUserRepo(user), d);

    test('texto direto: injeta data/nome e grava histórico', () async {
      final ai = _FakeAiRepo([_text('  Olá!  ')]);
      final result = await build(ai, _FakeDispatch({}))(
        'oi',
        now: DateTime(2026, 11, 3),
      );

      expect((result as Ok<AgentTurnResult>).value.text, 'Olá!');
      expect(ai.lastSystem, contains('2026-11-03'));
      expect(ai.lastSystem, contains('David'));
      expect(ai.history.map((m) => m.role), [AgentRole.user, AgentRole.model]);
      expect(ai.usage, 1);
    });

    test('loop: tool de leitura → resultado volta ao modelo → texto', () async {
      final ai = _FakeAiRepo([
        _call('list_budgets'),
        _text('Você tem 2 pendentes.'),
      ]);
      final card = AgentToolOutcome(
        modelPayload: const {'count': 2},
        messages: const [],
      );
      final d = _FakeDispatch({'list_budgets': card});
      final result = await build(ai, d)('pendentes do mês');

      expect(
        (result as Ok<AgentTurnResult>).value.text,
        'Você tem 2 pendentes.',
      );
      expect(ai.sends, 2);
      expect(d.calls, ['list_budgets']);
      expect(ai.history.map((m) => m.role), [
        AgentRole.user,
        AgentRole.model, // chamada de tool (parts cruas)
        AgentRole.tool, // resposta
        AgentRole.model, // texto final
      ]);
      // Parts cruas preservadas (thoughtSignature).
      expect(ai.history[1].rawParts.single['thoughtSignature'], 'sig');
      expect(ai.history[2].toolResponse, {'count': 2});
    });

    test('escrita: para no preview sem nova chamada ao modelo', () async {
      final ai = _FakeAiRepo([_call('create_receipt')]);
      final d = _FakeDispatch({
        'create_receipt': const AgentToolOutcome(
          modelPayload: {'status': 'awaiting_user_confirmation'},
          pending: AgentPendingAction('create_receipt', {'budget_id': 'b1'}),
          previewText: 'Criar recibo?',
        ),
      });
      final result = await build(ai, d)('recibo de 500 pro João');

      final turn = (result as Ok<AgentTurnResult>).value;
      expect(turn.pending?.toolName, 'create_receipt');
      expect(turn.text, 'Criar recibo?');
      expect(ai.sends, 1);
      expect(ai.history.last.role, AgentRole.model);
    });

    test('handoff start_flow devolve a opção do menu', () async {
      final ai = _FakeAiRepo([_call('start_flow')]);
      final d = _FakeDispatch({
        'start_flow': const AgentToolOutcome(menuOption: '1'),
      });
      final result = await build(ai, d)('criar orçamento');
      expect((result as Ok<AgentTurnResult>).value.menuOption, '1');
    });

    test('limite diário bloqueia sem chamar o modelo', () async {
      final ai = _FakeAiRepo([])..usage = RunAgentTurnUsecase.dailyLimit;
      final result = await build(ai, _FakeDispatch({}))('oi');

      expect(
        (result as Error<AgentTurnResult>).error,
        isA<AiDailyLimitException>(),
      );
      expect(ai.sends, 0);
    });

    test('loop infinito de tools é cortado', () async {
      final ai = _FakeAiRepo(List.generate(10, (_) => _call('list_budgets')));
      final d = _FakeDispatch({'list_budgets': const AgentToolOutcome()});
      final result = await build(ai, d)('x');
      expect(result, isA<Error<AgentTurnResult>>());
      expect(ai.sends, 5);
    });

    test('erro do modelo / resposta vazia viram Error (fallback)', () async {
      final ai1 = _FakeAiRepo([Result.error(Exception('quota'))]);
      expect(
        await build(ai1, _FakeDispatch({}))('oi'),
        isA<Error<AgentTurnResult>>(),
      );
      final ai2 = _FakeAiRepo([_text('  ')]);
      expect(
        await build(ai2, _FakeDispatch({}))('oi'),
        isA<Error<AgentTurnResult>>(),
      );
    });
  });
}
