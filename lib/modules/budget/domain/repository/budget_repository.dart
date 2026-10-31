import 'package:flutter/foundation.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Contrato do repositório de orçamentos.
///
/// Estende [ChangeNotifier] para permitir que a UI escute mudanças
/// na lista de orçamentos carregada em memória.
abstract class BudgetRepository extends ChangeNotifier {
  /// Lista cacheada de orçamentos.
  List<CustomerInfo> get budgets;

  /// Orçamento atualmente selecionado (útil para fluxos de edição).
  CustomerInfo? get selectedBudget;

  /// Itens cacheados de um orçamento específico.
  List<ItemsBudget> getBudgetItems(String budgetId);

  /// Comentários cacheados de um orçamento específico.
  List<ObservationBudget> getComments(String budgetId);

  /// Carrega todos os orçamentos. Usa cache a menos que [forceRefresh] seja true.
  Future<Result<List<CustomerInfo>>> fetchBudgets({bool forceRefresh = false});

  /// Busca orçamentos do mês corrente (range de IDs).
  Future<Result<List<CustomerInfo>>> fetchBudgetsByMonthRange(
      String startId, String endId);

  /// Busca um orçamento por ID (atualiza [selectedBudget]).
  Future<Result<CustomerInfo>> getBudgetById(String id);

  /// Cria ou sobrescreve um orçamento.
  Future<Result<void>> saveBudget(CustomerInfo budget);

  /// Atualiza campos de um orçamento existente.
  Future<Result<void>> updateBudget(CustomerInfo budget);

  /// Exclui uma lista de orçamentos.
  Future<Result<void>> deleteBudgets(List<CustomerInfo> budgets);

  /// Duplica um orçamento com opções de cópia.
  Future<Result<CustomerInfo>> duplicateBudget({
    required String sourceId,
    required bool copyClientData,
    required bool copyItems,
    required bool copyComments,
  });

  /// Salva um item em um orçamento.
  Future<Result<void>> saveBudgetItem(String budgetId, ItemsBudget item);

  /// Exclui itens de um orçamento.
  Future<Result<void>> deleteBudgetItems(
      String budgetId, List<ItemsBudget> items);

  /// Adiciona comentários (observações) a um orçamento.
  Future<Result<void>> addComments(
      String budgetId, List<ObservationPdf> comments);

  /// Busca comentários de um orçamento e os cacheia.
  Future<Result<List<ObservationBudget>>> fetchComments(
      String budgetId, {bool forceRefresh = false});

  /// Busca itens de um orçamento e os cacheia.
  Future<Result<List<ItemsBudget>>> fetchBudgetItems(
      String budgetId, {bool forceRefresh = false});

  /// Seleciona um orçamento como ativo.
  void selectBudget(CustomerInfo? budget);

  /// Limpa o cache de itens de um orçamento.
  void clearItemsCache(String budgetId);
}
