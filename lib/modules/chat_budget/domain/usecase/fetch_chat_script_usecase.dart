import 'package:oflite/modules/chat_budget/domain/entity/chat_script_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_script_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Busca o script de mensagens do bot configurado no Firestore.
class FetchChatScriptUsecase {
  final ChatScriptRepository _repo;

  const FetchChatScriptUsecase(this._repo);

  Future<Result<ChatScriptEntity>> call() => _repo.fetchScript();
}
