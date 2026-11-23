import 'package:oflite/modules/core/ai_text/domain/entity/ai_text_exceptions.dart';
import 'package:oflite/modules/core/ai_text/domain/repository/ai_text_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Gera texto com IA respeitando o limite diário por usuário (custo, §20.7).
///
/// Cada chamada conta 1, mesmo se falhar (a requisição já foi paga).
/// Resposta vazia vira [AiTextEmptyException].
class GenerateAiTextUsecase {
  static const dailyLimit = 30;

  final AiTextRepository _repo;

  GenerateAiTextUsecase(this._repo);

  Future<Result<String>> call({
    required String system,
    required String prompt,
    int maxOutputTokens = 512,
    List<String>? jsonKeys,
    DateTime? now,
  }) async {
    final today = _isoDate(now ?? DateTime.now());
    final used = await _repo.usageOf(today);
    if (used >= dailyLimit) {
      return const Result.error(AiTextDailyLimitException());
    }
    await _repo.saveUsage(today, used + 1);
    final result = await _repo.generate(
      system: system,
      prompt: prompt,
      maxOutputTokens: maxOutputTokens,
      jsonKeys: jsonKeys,
    );
    if (result is Ok<String> && result.value.isEmpty) {
      return const Result.error(AiTextEmptyException());
    }
    return result;
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
