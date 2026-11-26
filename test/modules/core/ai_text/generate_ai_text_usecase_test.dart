import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/core/ai_text/domain/entity/ai_text_exceptions.dart';
import 'package:oflite/modules/core/ai_text/domain/repository/ai_text_repository.dart';
import 'package:oflite/modules/core/ai_text/domain/usecase/generate_ai_text_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeRepo implements AiTextRepository {
  _FakeRepo(this.reply);

  final Result<String> reply;
  int calls = 0;
  final Map<String, int> usage = {};
  List<String>? lastJsonKeys;

  @override
  Future<Result<String>> generate({
    required String system,
    required String prompt,
    int maxOutputTokens = 512,
    List<String>? jsonKeys,
    bool asList = false,
  }) async {
    calls++;
    lastJsonKeys = jsonKeys;
    return reply;
  }

  @override
  Future<int> usageOf(String day) async => usage[day] ?? 0;

  @override
  Future<void> saveUsage(String day, int count) async => usage[day] = count;
}

void main() {
  final day = DateTime(2026, 11, 22, 10);

  test('gera texto e conta 1 uso no dia', () async {
    final repo = _FakeRepo(const Result.ok('Olá'));
    final result = await GenerateAiTextUsecase(repo)(
      system: 's',
      prompt: 'p',
      jsonKeys: ['name'],
      now: day,
    );

    expect((result as Ok<String>).value, 'Olá');
    expect(repo.usage['2026-11-22'], 1);
    expect(repo.lastJsonKeys, ['name']);
  });

  test('no limite diário não chama a IA', () async {
    final repo = _FakeRepo(const Result.ok('x'))
      ..usage['2026-11-22'] = GenerateAiTextUsecase.dailyLimit;
    final result = await GenerateAiTextUsecase(repo)(
      system: 's',
      prompt: 'p',
      now: day,
    );

    expect((result as Error<String>).error, isA<AiTextDailyLimitException>());
    expect(repo.calls, 0);
  });

  test('outro dia zera o limite', () async {
    final repo = _FakeRepo(const Result.ok('x'))
      ..usage['2026-11-21'] = GenerateAiTextUsecase.dailyLimit;
    final result = await GenerateAiTextUsecase(repo)(
      system: 's',
      prompt: 'p',
      now: day,
    );

    expect(result, isA<Ok<String>>());
  });

  test('resposta vazia vira AiTextEmptyException e conta o uso', () async {
    final repo = _FakeRepo(const Result.ok(''));
    final result = await GenerateAiTextUsecase(repo)(
      system: 's',
      prompt: 'p',
      now: day,
    );

    expect((result as Error<String>).error, isA<AiTextEmptyException>());
    expect(repo.usage['2026-11-22'], 1);
  });

  test('erro do repositório é repassado', () async {
    final repo = _FakeRepo(Result.error(Exception('timeout')));
    final result = await GenerateAiTextUsecase(repo)(
      system: 's',
      prompt: 'p',
      now: day,
    );

    expect(result, isA<Error<String>>());
  });
}
