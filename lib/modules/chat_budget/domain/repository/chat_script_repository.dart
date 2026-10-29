import 'package:flutter/foundation.dart';
import 'package:oflite/modules/chat_budget/domain/entity/chat_script_entity.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Contrato para leitura do script de mensagens do bot.
///
/// Estende [ChangeNotifier] para permitir que a UI escute
/// mudanças quando o script é carregado/atualizado.
abstract class ChatScriptRepository extends ChangeNotifier {
  /// Script atualmente cacheado (pode ser null antes do fetch).
  ChatScriptEntity? get currentScript;

  /// Busca o script configurado no Firestore.
  /// Retorna [ChatScriptEntity.fallback] se o documento não existir.
  Future<Result<ChatScriptEntity>> fetchScript();
}
