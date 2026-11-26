import 'package:flutter/foundation.dart';
import 'package:oflite/modules/core/ai_text/data/datasource/ai_text_local_datasource.dart';
import 'package:oflite/modules/core/ai_text/data/datasource/ai_text_remote_datasource.dart';
import 'package:oflite/modules/core/ai_text/domain/repository/ai_text_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class AiTextRepositoryImpl implements AiTextRepository {
  final AiTextRemoteDatasource _remote;
  final AiTextLocalDatasource _local;

  AiTextRepositoryImpl(this._remote, this._local);

  @override
  Future<Result<String>> generate({
    required String system,
    required String prompt,
    int maxOutputTokens = 512,
    List<String>? jsonKeys,
    bool asList = false,
  }) async {
    try {
      final raw = await _remote.generate(
        system: system,
        prompt: prompt,
        maxOutputTokens: maxOutputTokens,
        jsonKeys: jsonKeys,
        asList: asList,
      );
      debugPrint(
        '[AiText] tokens in=${raw['inputTokens']} out=${raw['outputTokens']}',
      );
      return Result.ok((raw['text'] as String).trim());
    } on Exception catch (e) {
      debugPrint('[AiText] erro: $e');
      return Result.error(e);
    } catch (e) {
      debugPrint('[AiText] erro: $e');
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<int> usageOf(String day) => _local.usageOf(day);

  @override
  Future<void> saveUsage(String day, int count) => _local.saveUsage(day, count);
}
