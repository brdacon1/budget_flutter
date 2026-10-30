import 'dart:async';
import 'package:intl/intl.dart';
import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/items_list_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budgetGlobals;

class BudgetRepositoryImpl extends BudgetRepository {
  final BudgetRemoteDataSource _remote;

  BudgetRepositoryImpl(this._remote);

  // Cache em memória
  List<CustomerInfo> _budgets = [];
  CustomerInfo? _selectedBudget;
  final Map<String, List<ItemsBudget>> _itemsCache = {};
  final Map<String, List<ObservationBudget>> _commentsCache = {};

  @override
  List<CustomerInfo> get budgets => List.unmodifiable(_budgets);

  @override
  CustomerInfo? get selectedBudget => _selectedBudget;

  @override
  void selectBudget(CustomerInfo? budget) {
    _selectedBudget = budget;
    notifyListeners();
  }

  @override
  List<ItemsBudget> getBudgetItems(String budgetId) =>
      List.unmodifiable(_itemsCache[budgetId] ?? []);

  @override
  List<ObservationBudget> getComments(String budgetId) =>
      List.unmodifiable(_commentsCache[budgetId] ?? []);

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgets(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _budgets.isNotEmpty) {
      return Result.ok(_budgets);
    }
    try {
      final raw = await _remote.getBudgets();
      _budgets = raw.map((e) => CustomerInfo.fromMap(e)).toList();
      notifyListeners();
      return Result.ok(_budgets);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<CustomerInfo>> getBudgetById(String id) async {
    try {
      final raw = await _remote.getBudgetById(id);
      final budget = CustomerInfo.fromMap(raw);
      _selectedBudget = budget;
      notifyListeners();
      return Result.ok(budget);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveBudget(CustomerInfo budget) async {
    try {
      await _remote.saveBudget(budget.toJson());
      budgetGlobals.IDORCAMENTO = budget.id;
      budgetGlobals.VALORTOTAL = budget.totalValue ?? 0;

      // Atualiza cache se já existir
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index >= 0) {
        _budgets[index] = budget;
      } else {
        _budgets.insert(0, budget);
      }
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateBudget(CustomerInfo budget) async {
    try {
      await _remote.updateBudget(budget.id!, budget.toJson());
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index >= 0) {
        _budgets[index] = budget;
      }
      if (_selectedBudget?.id == budget.id) {
        _selectedBudget = budget;
      }
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteBudgets(List<CustomerInfo> budgetsToDelete) async {
    try {
      for (final b in budgetsToDelete) {
        if (b.id != null) {
          await _remote.deleteBudget(b.id!);
        }
      }
      _budgets.removeWhere((b) => budgetsToDelete.any((d) => d.id == b.id));
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<CustomerInfo>> duplicateBudget({
    required String sourceId,
    required bool copyClientData,
    required bool copyItems,
    required bool copyComments,
  }) async {
    try {
      final now = DateTime.now();
      final formatted = DateFormat('dd/MM/yyyy').format(now);
      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      final CustomerInfo newBudget;
      if (copyClientData) {
        final sourceRaw = await _remote.getBudgetById(sourceId);
        final source = CustomerInfo.fromMap(sourceRaw);
        newBudget = CustomerInfo(
          id: newId,
          data: formatted,
          customerName: source.customerName,
          phone: source.phone,
          status: source.status,
          email: source.email,
          address: source.address,
          generated: source.generated,
          companyName: source.companyName,
          zip: source.zip,
          street: source.street,
          city: source.city,
          neighborhood: source.neighborhood,
          totalValue: source.totalValue,
        );
      } else {
        newBudget = CustomerInfo(
          id: newId,
          data: formatted,
          customerName: 'Duplicado de: $sourceId',
          status: '',
        );
      }

      await _remote.saveBudget(newBudget.toJson());

      if (copyItems) {
        final itemsRaw = await _remote.getItemsByBudgetId(sourceId);
        for (final raw in itemsRaw) {
          final item = ItemsListBudget.fromMap(raw);
          await _remote.saveBudgetItem(
            newId,
            item.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
            item.toJson(),
          );
        }
      }

      if (copyComments) {
        final commentsRaw = await _remote.getComments(sourceId);
        for (final raw in commentsRaw) {
          await _remote.addComment(newId, raw);
        }
      }

      _budgets.insert(0, newBudget);
      budgetGlobals.IDORCAMENTO = '';
      notifyListeners();
      return Result.ok(newBudget);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveBudgetItem(
      String budgetId, ItemsBudget item) async {
    try {
      await _remote.saveBudgetItem(
        budgetId,
        item.id ?? '',
        item.toJson(),
      );
      // Atualiza cache de itens
      final list = _itemsCache.putIfAbsent(budgetId, () => []);
      final index = list.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        list[index] = item;
      } else {
        list.add(item);
      }
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteBudgetItems(
      String budgetId, List<ItemsBudget> items) async {
    try {
      for (final item in items) {
        if (item.id != null) {
          await _remote.deleteBudgetItem(budgetId, item.id!);
        }
      }
      final list = _itemsCache[budgetId];
      if (list != null) {
        list.removeWhere((i) => items.any((d) => d.id == i.id));
      }
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> addComments(
      String budgetId, List<ObservationPdf> comments) async {
    try {
      final now = DateTime.now();
      final formatted = DateFormat('dd/MM/yyyy').format(now);
      for (final c in comments) {
        await _remote.addComment(budgetId, {
          'OBSERVACAO': c.observacao,
          'DATA': formatted,
        });
      }
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<ObservationBudget>>> fetchComments(
      String budgetId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _commentsCache.containsKey(budgetId)) {
      return Result.ok(_commentsCache[budgetId]!);
    }
    try {
      final raw = await _remote.getComments(budgetId);
      final list =
          raw.map((e) => ObservationBudget.fromMap(e)).toList();
      _commentsCache[budgetId] = list;
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<ItemsBudget>>> fetchBudgetItems(
      String budgetId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _itemsCache.containsKey(budgetId)) {
      return Result.ok(_itemsCache[budgetId]!);
    }
    try {
      final raw = await _remote.getBudgetItems(budgetId);
      final list = raw.map((e) => ItemsBudget.fromMap(e)).toList();
      _itemsCache[budgetId] = list;
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgetsByMonthRange(
      String startId, String endId) async {
    try {
      final raw = await _remote.getBudgetsByMonthRange(startId, endId);
      final list = raw.map((e) => CustomerInfo.fromMap(e)).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  void clearItemsCache(String budgetId) {
    _itemsCache.remove(budgetId);
  }
}
