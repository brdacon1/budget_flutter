import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/check_ai_access_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/run_agent_turn_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeUserRepo extends ChangeNotifier implements UserRepository {
  _FakeUserRepo(InfoUser? user) : selectUser = ValueNotifier(user);

  @override
  ValueNotifier<InfoUser?> selectUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAiRepo implements ChatAiRepository {
  _FakeAiRepo(this.reply);

  Result<AgentReplyEntity> reply;
  String? lastSystem;
  List<AgentToolSpec> lastTools = const [];
  final List<AgentMessageEntity> _history = [];

  @override
  List<AgentMessageEntity> get history => _history;

  @override
  void addMessage(AgentMessageEntity message) => _history.add(message);

  @override
  void clearHistory() => _history.clear();

  @override
  Future<Result<AgentReplyEntity>> send(
    String system, {
    List<AgentToolSpec> tools = const [],
  }) async {
    lastSystem = system;
    lastTools = tools;
    return reply;
  }
}

Result<AgentReplyEntity> _text(String t) =>
    Result.ok(AgentReplyEntity(text: t));

Result<AgentReplyEntity> _flow(String flow) => Result.ok(
  AgentReplyEntity(
    toolCalls: [
      AgentToolCallEntity('start_flow', {'flow': flow}),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CheckAiAccessUsecase', () {
    bool off() => false;

    test('assinante tem acesso', () {
      final user = InfoUser()..autoRenewing = true;
      expect(
        CheckAiAccessUsecase(_FakeUserRepo(user), forcePremium: off)(),
        isTrue,
      );
    });

    test('FORCE_PREMIUM libera mesmo sem pagamento', () {
      expect(
        CheckAiAccessUsecase(_FakeUserRepo(null), forcePremium: () => true)(),
        isTrue,
      );
    });

    test('não-assinante e usuário nulo não têm acesso', () {
      expect(
        CheckAiAccessUsecase(_FakeUserRepo(InfoUser()), forcePremium: off)(),
        isFalse,
      );
      expect(
        CheckAiAccessUsecase(_FakeUserRepo(null), forcePremium: off)(),
        isFalse,
      );
    });
  });

  group('RunAgentTurnUsecase', () {
    final user = InfoUser()..name = 'David';

    test('texto: grava user + model, injeta data/nome e envia tools', () async {
      final ai = _FakeAiRepo(_text('  Olá!  '));
      final result = await RunAgentTurnUsecase(ai, _FakeUserRepo(user))(
        'oi',
        now: DateTime(2026, 11, 3),
      );

      final value = (result as Ok<AgentTurnResult>).value;
      expect(value.text, 'Olá!');
      expect(value.menuOption, isNull);
      expect(ai.history.map((m) => m.role), [AgentRole.user, AgentRole.model]);
      expect(ai.lastSystem, contains('2026-11-03'));
      expect(ai.lastSystem, contains('David'));
      expect(ai.lastTools.single.name, 'start_flow');
    });

    test('start_flow mapeia cada fluxo para a opção do menu', () async {
      const expected = {
        'create_budget': '1',
        'price_list': '2',
        'pdf_edit': '3',
        'change_username': '4',
      };
      for (final e in expected.entries) {
        final ai = _FakeAiRepo(_flow(e.key));
        final result = await RunAgentTurnUsecase(ai, _FakeUserRepo(user))('x');
        expect((result as Ok<AgentTurnResult>).value.menuOption, e.value);
        expect(ai.history.last.role, AgentRole.model);
      }
    });

    test('fluxo desconhecido sem texto vira Error (fallback)', () async {
      final ai = _FakeAiRepo(_flow('delete_all'));
      final result = await RunAgentTurnUsecase(ai, _FakeUserRepo(user))('x');
      expect(result, isA<Error<AgentTurnResult>>());
    });

    test('erro do modelo devolve Error e não grava resposta', () async {
      final ai = _FakeAiRepo(Result.error(Exception('quota')));
      final result = await RunAgentTurnUsecase(ai, _FakeUserRepo(user))('oi');

      expect(result, isA<Error<AgentTurnResult>>());
      expect(ai.history.single.role, AgentRole.user);
    });

    test('resposta vazia vira Error (VM mostra fallback)', () async {
      final ai = _FakeAiRepo(_text('   '));
      final result = await RunAgentTurnUsecase(ai, _FakeUserRepo(user))('oi');

      expect(result, isA<Error<AgentTurnResult>>());
    });
  });
}
