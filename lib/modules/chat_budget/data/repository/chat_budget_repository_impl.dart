import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/chat_budget/data/datasource/chat_budget_remote_datasource.dart';
import 'package:oflite/modules/chat_budget/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_budget/domain/repository/chat_budget_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budgetGlobals;
import 'package:oflite/shared/models/items_budget.dart';

/// Implementação do [ChatBudgetRepository].
///
/// Orquestra:
/// - Criação/edição de orçamentos via [BudgetRepository] (injetado)
/// - Persistência de mensagens de chat no Firestore
class ChatBudgetRepositoryImpl extends ChatBudgetRepository {
  final ChatBudgetRemoteDataSource _chatRemote;
  final BudgetRepository _budgetRepo;

  String? _sessionId;
  CustomerInfo? _draft;
  final List<ChatMessageEntity> _messages = [];
  String? _currentFlowStep;

  ChatBudgetRepositoryImpl(this._chatRemote, this._budgetRepo);

  @override
  String? get currentSessionId => _sessionId;

  @override
  CustomerInfo? get draftBudget => _draft;

  @override
  List<ChatMessageEntity> get messages => List.unmodifiable(_messages);

  @override
  String? get currentFlowStep => _currentFlowStep;

  @override
  void setCurrentFlowStep(String? step) {
    _currentFlowStep = step;
  }

  String _generateSessionId() {
    final now = DateTime.now();
    final randomPart = Random().nextInt(9999999).toString().padLeft(7, '0');
    return '${now.millisecondsSinceEpoch}-$randomPart';
  }

  @override
  Future<Result<CustomerInfo>> createDraftBudget(
    String clientName, {
    String? phone,
  }) async {
    try {
      final now = DateTime.now();
      final id = now.millisecondsSinceEpoch.toString();
      final formattedDate = DateFormat('dd/MM/yyyy').format(now);

      final budget = CustomerInfo(
        id: id,
        data: formattedDate,
        customerName: clientName,
        phone: phone,
        status: 'PENDENTE',
        totalValue: 0,
      );

      final saveResult = await _budgetRepo.saveBudget(budget);
      if (saveResult is Error<void>) {
        return Result.error(saveResult.error);
      }

      _draft = budget;
      _sessionId = _generateSessionId();
      await _chatRemote.createSession(_sessionId!, {
        'budgetId': id,
        'createdAt': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return Result.ok(budget);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateDraftAddress({
    String? street,
    String? city,
    String? neighborhood,
    String? zip,
  }) async {
    if (_draft == null) {
      return Result.error(Exception('Rascunho não iniciado'));
    }
    try {
      final updated = _draft!.copyWith(
        street: street,
        city: city,
        neighborhood: neighborhood,
        zip: zip,
      );
      await _budgetRepo.updateBudget(updated);
      _draft = updated;
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> addItemsToDraft(List<ItemsBudget> items) async {
    if (_draft?.id == null) {
      return Result.error(Exception('Rascunho não iniciado'));
    }
    try {
      for (final it in items) {
        // Gera ID se não tiver
        final itemWithId = it;
        if (itemWithId.id == null || itemWithId.id!.isEmpty) {
          itemWithId.id = DateTime.now().millisecondsSinceEpoch.toString();
        }
        await _budgetRepo.saveBudgetItem(_draft!.id!, itemWithId);
      }
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> removeItemsFromDraft(List<ItemsBudget> items) async {
    if (_draft?.id == null) {
      return Result.error(Exception('Rascunho não iniciado'));
    }
    try {
      await _budgetRepo.deleteBudgetItems(_draft!.id!, items);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendMessage(ChatMessageEntity message) async {
    _messages.add(message);
    if (_sessionId != null) {
      try {
        await _chatRemote.saveMessage(_sessionId!, {
          'sender': message.sender.name,
          'type': message.type.name,
          'content': message.content,
          'payload': message.payload,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Falha silenciosa — mensagens ainda estão em memória
      }
    }
    notifyListeners();
    return Result.ok(null);
  }

  @override
  Future<Result<void>> updateMessage(String id, String newContent) async {
    final i = _messages.indexWhere((m) => m.id == id);
    if (i == -1) {
      return Result.error(Exception('Mensagem não encontrada'));
    }
    _messages[i] = _messages[i].copyWith(content: newContent);
    notifyListeners();
    return Result.ok(null);
  }

  @override
  Future<Result<void>> removeMessageById(String id) async {
    _messages.removeWhere((m) => m.id == id);
    notifyListeners();
    return Result.ok(null);
  }

  @override
  Future<Result<List<ItemsBudget>>> fetchDraftItems() async {
    if (_draft?.id == null) {
      return Result.error(Exception('Rascunho não iniciado'));
    }
    try {
      final result = await _budgetRepo.fetchBudgetItems(
        _draft!.id!,
        forceRefresh: true,
      );
      notifyListeners();
      return result;
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> refreshDraftTotal() async {
    if (_draft?.id == null) {
      return Result.error(Exception('Rascunho não iniciado'));
    }
    try {
      final itemsResult = await _budgetRepo.fetchBudgetItems(
        _draft!.id!,
        forceRefresh: true,
      );
      double total = 0;
      if (itemsResult is Ok<List<ItemsBudget>>) {
        for (final it in itemsResult.value) {
          total += it.TOTAL ?? 0;
        }
      }
      final updated = _draft!.copyWith(totalValue: total);
      await _budgetRepo.updateBudget(updated);
      _draft = updated;
      budgetGlobals.VALORTOTAL = total;
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<CustomerInfo>> finalizeDraft() async {
    if (_draft == null) {
      return Result.error(Exception('Rascunho não iniciado'));
    }
    try {
      // Reutiliza o recálculo já implementado
      final totalResult = await refreshDraftTotal();
      if (totalResult is Error<void>) {
        return Result.error(totalResult.error);
      }

      // Mantém o status que já estava; se vazio, força 'PENDENTE' igual à tela
      final currentStatus = _draft!.status;
      final finalized = _draft!.copyWith(
        status: (currentStatus == null || currentStatus.isEmpty) ? 'PENDENTE' : currentStatus,
      );
      await _budgetRepo.updateBudget(finalized);
      _draft = finalized;
      budgetGlobals.IDORCAMENTO = finalized.id;
      budgetGlobals.VALORTOTAL = finalized.totalValue ?? 0;
      notifyListeners();
      return Result.ok(finalized);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  void clearSession() {
    _sessionId = null;
    _draft = null;
    _messages.clear();
    notifyListeners();
  }

  @override
  Future<Result<void>> deleteDraft() async {
    if (_draft == null || _draft!.id == null) {
      return Result.ok(null);
    }
    try {
      // Limpa cache de itens do BudgetRepository para este draft
      _budgetRepo.clearItemsCache(_draft!.id!);
      // Deleta o orçamento do banco
      await _budgetRepo.deleteBudgets([_draft!]);
      _draft = null;
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
