import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/entity/comment_library_exceptions.dart';
import 'package:oflite/modules/comment_library/domain/repository/comment_library_repository.dart';
import 'package:oflite/modules/comment_library/domain/usecase/add_library_comments_to_budget_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/check_comment_library_access_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/generate_comment_name_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/improve_comment_text_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/save_library_comment_usecase.dart';
import 'package:oflite/modules/core/ai_text/domain/entity/ai_text_exceptions.dart';
import 'package:oflite/modules/core/ai_text/domain/usecase/generate_ai_text_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeUserRepo extends ChangeNotifier implements UserRepository {
  _FakeUserRepo(InfoUser? user) : selectUser = ValueNotifier(user);

  @override
  ValueNotifier<InfoUser?> selectUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAi implements GenerateAiTextUsecase {
  _FakeAi(this.reply);

  Result<String> reply;
  int calls = 0;

  @override
  Future<Result<String>> call({
    required String system,
    required String prompt,
    int maxOutputTokens = 512,
    List<String>? jsonKeys,
    DateTime? now,
  }) async {
    calls++;
    return reply;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLibraryRepo implements CommentLibraryRepository {
  final added = <CommentLibraryModel>[];
  final updated = <CommentLibraryModel>[];
  bool fail = false;

  @override
  Future<Result<String>> addComment(CommentLibraryModel comment) async {
    if (fail) return Result.error(Exception('firestore'));
    added.add(comment);
    return const Result.ok('new-id');
  }

  @override
  Future<Result<void>> updateComment(CommentLibraryModel comment) async {
    if (fail) return Result.error(Exception('firestore'));
    updated.add(comment);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deleteComments(List<CommentLibraryModel> c) async =>
      const Result.ok(null);

  @override
  Future<Result<List<CommentLibraryModel>>> fetchComments() async =>
      const Result.ok([]);
}

class _FakeBudgetComments extends ChangeNotifier
    implements BudgetCommentRepository {
  final added = <String>[];
  int failAt = -1;

  @override
  Future<Result<void>> addComment(String budgetId, String text) async {
    if (added.length == failAt) return Result.error(Exception('firestore'));
    added.add(text);
    return const Result.ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CheckCommentLibraryAccessUsecase', () {
    bool off() => false;
    bool on() => true;

    test('assinante tem acesso', () {
      final u = InfoUser()..autoRenewing = true;
      expect(
        CheckCommentLibraryAccessUsecase(_FakeUserRepo(u), forcePremium: off)(),
        isTrue,
      );
    });

    test('trial ativo tem acesso; expirado não', () {
      final active = InfoUser()..trialStartedAt = DateTime.now();
      final expired =
          InfoUser()
            ..trialStartedAt = DateTime.now().subtract(const Duration(days: 3));
      expect(
        CheckCommentLibraryAccessUsecase(
          _FakeUserRepo(active),
          forcePremium: off,
        )(),
        isTrue,
      );
      expect(
        CheckCommentLibraryAccessUsecase(
          _FakeUserRepo(expired),
          forcePremium: off,
        )(),
        isFalse,
      );
    });

    test('FORCE_PREMIUM libera', () {
      expect(
        CheckCommentLibraryAccessUsecase(
          _FakeUserRepo(
            InfoUser()
              ..trialStartedAt = DateTime.now().subtract(
                const Duration(days: 3),
              ),
          ),
          forcePremium: on,
        )(),
        isTrue,
      );
    });
  });

  group('GenerateCommentNameUsecase', () {
    test('usa o nome do JSON, limpo', () async {
      final ai = _FakeAi(
        const Result.ok('{"name": "\\"Garantia de 90 dias.\\""}'),
      );
      expect(
        await GenerateCommentNameUsecase(ai)('Garantia de 90 dias no serviço'),
        'Garantia de 90 dias',
      );
    });

    test('texto cru quando não vem JSON', () async {
      final ai = _FakeAi(const Result.ok('Forma de pagamento'));
      expect(await GenerateCommentNameUsecase(ai)('x'), 'Forma de pagamento');
    });

    test('corta em 40 caracteres', () async {
      final ai = _FakeAi(Result.ok('{"name": "${'a' * 60}"}'));
      expect((await GenerateCommentNameUsecase(ai)('x')).length, 40);
    });

    test('falha da IA → primeiras palavras do texto', () async {
      final ai = _FakeAi(Result.error(const AiTextDailyLimitException()));
      expect(
        await GenerateCommentNameUsecase(ai)(
          'Pagamento em 3x no cartão sem juros, entrada de 30% na aprovação.',
        ),
        'Pagamento em 3x no cartão sem juros',
      );
    });

    test('JSON com nome vazio → fallback', () async {
      final ai = _FakeAi(const Result.ok('{"name": ""}'));
      expect(
        await GenerateCommentNameUsecase(ai)('Prazo curto'),
        'Prazo curto',
      );
    });
  });

  group('ImproveCommentTextUsecase', () {
    test('devolve o texto melhorado', () async {
      final ai = _FakeAi(const Result.ok(' Garantia de 90 dias. '));
      final r = await ImproveCommentTextUsecase(ai)('garantia 90 dia');
      expect((r as Ok<String>).value, 'Garantia de 90 dias.');
    });

    test('texto vazio não chama a IA', () async {
      final ai = _FakeAi(const Result.ok('x'));
      final r = await ImproveCommentTextUsecase(ai)('   ');
      expect((r as Error<String>).error, isA<CommentTextEmptyException>());
      expect(ai.calls, 0);
    });

    test('rejeita se perder um número', () async {
      final ai = _FakeAi(const Result.ok('Garantia de noventa dias.'));
      final r = await ImproveCommentTextUsecase(ai)('garantia 90 dias');
      expect((r as Error<String>).error, isA<CommentImproveInvalidException>());
    });

    test('rejeita texto longo demais', () async {
      final ai = _FakeAi(Result.ok('a' * 1001));
      final r = await ImproveCommentTextUsecase(ai)('texto');
      expect((r as Error<String>).error, isA<CommentImproveInvalidException>());
    });

    test('erro da IA é repassado', () async {
      final ai = _FakeAi(Result.error(Exception('timeout')));
      expect(
        await ImproveCommentTextUsecase(ai)('texto'),
        isA<Error<String>>(),
      );
    });
  });

  group('SaveLibraryCommentUsecase', () {
    late _FakeLibraryRepo repo;
    late _FakeBudgetComments budget;
    late _FakeAi ai;
    late SaveLibraryCommentUsecase save;

    setUp(() {
      repo = _FakeLibraryRepo();
      budget = _FakeBudgetComments();
      ai = _FakeAi(const Result.ok('{"name": "Garantia"}'));
      save = SaveLibraryCommentUsecase(
        repo,
        GenerateCommentNameUsecase(ai),
        budget,
      );
    });

    test('texto vazio não chama IA nem grava', () async {
      final r = await save(text: '  ');
      expect((r as Error).error, isA<CommentTextEmptyException>());
      expect(ai.calls, 0);
      expect(repo.added, isEmpty);
    });

    test('texto longo demais', () async {
      final r = await save(text: 'a' * 1001);
      expect((r as Error).error, isA<CommentTextTooLongException>());
    });

    test('cria com nome da IA', () async {
      final r = await save(text: ' Garantia de 90 dias ');
      final c = (r as Ok<CommentLibraryModel>).value;
      expect(c.id, 'new-id');
      expect(c.name, 'Garantia');
      expect(c.text, 'Garantia de 90 dias');
      expect(budget.added, isEmpty);
    });

    test('IA falhou → grava com nome fallback', () async {
      ai.reply = Result.error(Exception('offline'));
      final r = await save(text: 'Prazo de entrega 10 dias');
      expect(
        (r as Ok<CommentLibraryModel>).value.name,
        'Prazo de entrega 10 dias',
      );
    });

    test('nome informado não chama a IA', () async {
      await save(text: 'texto', name: 'Meu nome');
      expect(ai.calls, 0);
      expect(repo.added.single.name, 'Meu nome');
    });

    test('edição atualiza', () async {
      final r = await save(id: 'abc', text: 'novo', name: 'Nome');
      expect(r, isA<Ok<CommentLibraryModel>>());
      expect(repo.updated.single.id, 'abc');
      expect(repo.added, isEmpty);
    });

    test('com budgetId grava também no orçamento', () async {
      await save(text: 'Garantia', budgetId: 'b1');
      expect(budget.added, ['Garantia']);
    });

    test('falha ao vincular no orçamento', () async {
      budget.failAt = 0;
      final r = await save(text: 'Garantia', budgetId: 'b1');
      final e = (r as Error).error as CommentSavedButNotLinkedException;
      expect(e.commentId, 'new-id');
      expect(repo.added, hasLength(1));
    });

    test('erro do Firestore não vincula', () async {
      repo.fail = true;
      final r = await save(text: 'Garantia', budgetId: 'b1');
      expect(r, isA<Error>());
      expect(budget.added, isEmpty);
    });
  });

  group('AddLibraryCommentsToBudgetUsecase', () {
    const a = CommentLibraryModel(id: '1', name: 'A', text: 'texto A');
    const b = CommentLibraryModel(id: '2', name: 'B', text: 'texto B');

    test('copia os textos na ordem', () async {
      final budget = _FakeBudgetComments();
      final r = await AddLibraryCommentsToBudgetUsecase(budget)('b1', [a, b]);
      expect(r, isA<Ok<void>>());
      expect(budget.added, ['texto A', 'texto B']);
    });

    test('para no primeiro erro', () async {
      final budget = _FakeBudgetComments()..failAt = 1;
      final r = await AddLibraryCommentsToBudgetUsecase(budget)('b1', [a, b]);
      expect(r, isA<Error<void>>());
      expect(budget.added, ['texto A']);
    });
  });
}
