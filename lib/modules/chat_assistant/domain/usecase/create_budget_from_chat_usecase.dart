import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_script_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_script_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';

/// Orquestra a criação completa de um orçamento via chat.
///
/// Responsável por carregar o script e executar os passos do fluxo
/// conforme interação do usuário, delegando I/O ao [ChatBudgetRepository].
class CreateBudgetFromChatUsecase {
  final ChatBudgetRepository _chatRepo;
  final ChatScriptRepository _scriptRepo;

  const CreateBudgetFromChatUsecase(this._chatRepo, this._scriptRepo);

  /// Script atual (fallback incluído).
  ChatScriptEntity? get script => _scriptRepo.currentScript;

  /// Garante que o script está carregado.
  Future<Result<ChatScriptEntity>> ensureScriptLoaded() async {
    final current = _scriptRepo.currentScript;
    if (current != null) return Result.ok(current);
    return _scriptRepo.fetchScript();
  }

  /// Cria o orçamento vazio a partir do nome do cliente.
  Future<Result<CustomerInfo>> createDraft(
    String clientName, {
    String? phone,
  }) async {
    return _chatRepo.createDraftBudget(clientName, phone: phone);
  }

  /// Atualiza endereço completo no rascunho.
  Future<Result<void>> updateAddress({
    String? street,
    String? city,
    String? neighborhood,
    String? zip,
  }) async {
    return _chatRepo.updateDraftAddress(
      street: street,
      city: city,
      neighborhood: neighborhood,
      zip: zip,
    );
  }

  /// Adiciona produtos ao rascunho.
  Future<Result<void>> addProducts(List<ItemsBudget> items) async {
    return _chatRepo.addItemsToDraft(items);
  }

  /// Finaliza o rascunho e retorna o orçamento completo.
  Future<Result<CustomerInfo>> finalize() async {
    return _chatRepo.finalizeDraft();
  }

  /// Envia uma mensagem de sistema para o chat.
  Future<Result<void>> sendSystemMessage(ChatMessageEntity message) async {
    return _chatRepo.sendMessage(message);
  }
}
