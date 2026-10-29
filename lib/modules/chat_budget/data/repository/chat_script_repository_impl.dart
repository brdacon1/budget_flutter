import 'package:flutter/foundation.dart';
import 'package:oflite/modules/chat_budget/data/datasource/chat_script_remote_datasource.dart';
import 'package:oflite/modules/chat_budget/domain/entity/chat_script_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_script_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Implementação do [ChatScriptRepository].
///
/// Mantém cache em memória do último script carregado.
class ChatScriptRepositoryImpl extends ChatScriptRepository {
  final ChatScriptRemoteDataSource _remote;

  ChatScriptEntity? _cached;

  ChatScriptRepositoryImpl(this._remote);

  @override
  ChatScriptEntity? get currentScript => _cached;

  @override
  Future<Result<ChatScriptEntity>> fetchScript() async {
    try {
      final raw = await _remote.getScript();
      if (raw == null || raw.isEmpty) {
        _cached = ChatScriptEntity.fallback;
      } else {
        _cached = ChatScriptEntity(
          welcomeMessage: raw['welcomeMessage'] as String? ??
              ChatScriptEntity.fallback.welcomeMessage,
          askClientName: raw['askClientName'] as String? ??
              ChatScriptEntity.fallback.askClientName,
          askPhone: raw['askPhone'] as String? ??
              ChatScriptEntity.fallback.askPhone,
          askAddress: raw['askAddress'] as String? ??
              ChatScriptEntity.fallback.askAddress,
          askHasCep: raw['askHasCep'] as String? ??
              ChatScriptEntity.fallback.askHasCep,
          askCep: raw['askCep'] as String? ??
              ChatScriptEntity.fallback.askCep,
          cepNotFound: raw['cepNotFound'] as String? ??
              ChatScriptEntity.fallback.cepNotFound,
          askStreetFallback: raw['askStreetFallback'] as String? ??
              ChatScriptEntity.fallback.askStreetFallback,
          askProducts: raw['askProducts'] as String? ??
              ChatScriptEntity.fallback.askProducts,
          finalMessage: raw['finalMessage'] as String? ??
              ChatScriptEntity.fallback.finalMessage,
          shareLabel: raw['shareLabel'] as String? ??
              ChatScriptEntity.fallback.shareLabel,
        );
      }
      notifyListeners();
      return Result.ok(_cached!);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
