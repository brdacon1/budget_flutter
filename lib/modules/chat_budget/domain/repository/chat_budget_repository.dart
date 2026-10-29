import 'package:flutter/foundation.dart';
import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/shared/models/items_budget.dart';

/// Contrato que une:
/// 1) CRUD de mensagens de sessão
/// 2) Criação/edição de orçamentos via [BudgetRepository] (injetado)
/// 3) Salvamento de itens de orçamento
abstract class ChatBudgetRepository extends ChangeNotifier {
  /// ID da sessão de chat atual (null se não iniciada).
  String? get currentSessionId;

  /// Orçamento rascunho sendo construído na sessão atual.
  CustomerInfo? get draftBudget;

  /// Mensagens da sessão atual (cache em memória).
  List<ChatMessageEntity> get messages;

  /// Inicia uma nova sessão de chat e cria o orçamento vazio no Firebase.
  Future<Result<CustomerInfo>> createDraftBudget(
    String clientName, {
    String? phone,
  });

  /// Atualiza endereço no rascunho.
  Future<Result<void>> updateDraftAddress({
    String? street,
    String? city,
    String? neighborhood,
    String? zip,
  });

  /// Adiciona itens ao rascunho e grava no Firestore.
  Future<Result<void>> addItemsToDraft(List<ItemsBudget> items);

  /// Remove itens do rascunho.
  Future<Result<void>> removeItemsFromDraft(List<ItemsBudget> items);

  /// Salva uma mensagem na sessão ativa (localmente + remoto opcional).
  Future<Result<void>> sendMessage(ChatMessageEntity message);

  /// Atualiza o texto de uma mensagem existente pelo ID.
  Future<Result<void>> updateMessage(String id, String newContent);

  /// Remove uma mensagem da sessão pelo ID.
  Future<Result<void>> removeMessageById(String id);

  /// Busca os itens salvos no orçamento rascunho atual.
  Future<Result<List<ItemsBudget>>> fetchDraftItems();

  /// Marca sessão como completa e devolve o orçamento final.
  Future<Result<CustomerInfo>> finalizeDraft();

  /// Limpa sessão atual e cache de mensagens.
  void clearSession();

  /// Recalcula o total do rascunho com base nos itens salvos no Firestore.
  Future<Result<void>> refreshDraftTotal();

  /// Deleta o orçamento rascunho atual e limpa caches relacionados.
  Future<Result<void>> deleteDraft();

  /// Step atual do fluxo conversacional (persistido para restaurar estado).
  String? get currentFlowStep;

  /// Atualiza o step do fluxo conversacional.
  void setCurrentFlowStep(String? step);
}
