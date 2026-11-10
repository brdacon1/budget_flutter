import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/items_list_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class BudgetRepositoryImpl extends BudgetRepository {
  final BudgetRemoteDataSource _remote;
  final UserRepository _userRepository;

  BudgetRepositoryImpl(this._remote, this._userRepository);

  String? get _userUid => _userRepository.selectUser.value?.user;

  // Cache em memória
  List<CustomerInfo> _budgets = [];
  CustomerInfo? _selectedBudget;
  final Map<String, List<ItemsBudget>> _itemsCache = {};
  final Map<String, List<ObservationBudget>> _commentsCache = {};

  @override
  List<CustomerInfo> get budgets => List.unmodifiable(_budgets);

  final ValueNotifier<CustomerInfo?> _selectBudget =
      ValueNotifier<CustomerInfo?>(null);

  @override
  ValueNotifier<CustomerInfo?> get selectBudget => _selectBudget;

  @override
  set selectBudget(ValueNotifier<CustomerInfo?> value) {
    _selectBudget.value = value.value;
  }

  @override
  void clearSelectBudget() {
    _selectBudget.value = null;
  }

  @override
  CustomerInfo? get selectedBudget => _selectedBudget;

  @override
  List<ItemsBudget> getBudgetItems(String budgetId) =>
      List.unmodifiable(_itemsCache[budgetId] ?? []);

  @override
  List<ObservationBudget> getComments(String budgetId) =>
      List.unmodifiable(_commentsCache[budgetId] ?? []);

  // Paginação
  String? _lastBudgetId;
  bool _hasMoreBudgets = true;
  bool _isLoadingMoreBudgets = false;

  @override
  bool get hasMoreBudgets => _hasMoreBudgets;

  @override
  bool get isLoadingMoreBudgets => _isLoadingMoreBudgets;

  @override
  Future<Result<int>> countBudgets() async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final count = await _remote.countBudgets(userUid);
      return Result.ok(count);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgets({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _budgets.isNotEmpty) {
      return Result.ok(_budgets);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _remote.getBudgets(userUid);
      _budgets = raw.map((e) => CustomerInfo.fromMap(e)).toList();
      notifyListeners();
      return Result.ok(_budgets);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgetsPaginated({
    bool refresh = false,
  }) async {
    if (_isLoadingMoreBudgets) return Result.ok(_budgets);

    if (refresh) {
      _budgets.clear();
      _lastBudgetId = null;
      _hasMoreBudgets = true;
    }

    if (!_hasMoreBudgets) return Result.ok(_budgets);

    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }

    _isLoadingMoreBudgets = true;
    notifyListeners();

    try {
      final raw = await _remote.getBudgetsPaginated(
        userUid,
        limit: 7,
        startAfterId: _lastBudgetId,
      );

      if (raw.isEmpty) {
        _hasMoreBudgets = false;
      } else {
        final newBudgets = raw.map((e) => CustomerInfo.fromMap(e)).toList();
        _lastBudgetId = newBudgets.last.id;
        _budgets.addAll(newBudgets);
        if (newBudgets.length < 7) {
          _hasMoreBudgets = false;
        }
      }

      _isLoadingMoreBudgets = false;
      notifyListeners();
      return Result.ok(_budgets);
    } catch (e) {
      _isLoadingMoreBudgets = false;
      notifyListeners();
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<CustomerInfo>> getBudgetById(String id) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _remote.getBudgetById(userUid, id);
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
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      await _remote.saveBudget(userUid, budget.toJson());
      _selectBudget.value = budget;

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
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      await _remote.updateBudget(userUid, budget.id!, budget.toJson());
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
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      for (final b in budgetsToDelete) {
        if (b.id != null) {
          await _remote.deleteBudget(userUid, b.id!);
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
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final now = DateTime.now();
      final formatted = DateFormat('dd/MM/yyyy').format(now);
      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      final CustomerInfo newBudget;
      if (copyClientData) {
        final sourceRaw = await _remote.getBudgetById(userUid, sourceId);
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

      await _remote.saveBudget(userUid, newBudget.toJson());

      if (copyItems) {
        final itemsRaw = await _remote.getItemsByBudgetId(userUid, sourceId);
        for (final raw in itemsRaw) {
          final item = ItemsListBudget.fromMap(raw);
          await _remote.saveBudgetItem(
            userUid,
            newId,
            item.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
            item.toJson(),
          );
        }
      }

      if (copyComments) {
        final commentsRaw = await _remote.getComments(userUid, sourceId);
        for (final raw in commentsRaw) {
          await _remote.addComment(userUid, newId, raw);
        }
      }

      _budgets.insert(0, newBudget);
      _selectBudget.value = null;
      notifyListeners();
      return Result.ok(newBudget);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveBudgetItem(String budgetId, ItemsBudget item) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      await _remote.saveBudgetItem(
        userUid,
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
    String budgetId,
    List<ItemsBudget> items,
  ) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      for (final item in items) {
        if (item.id != null) {
          await _remote.deleteBudgetItem(userUid, budgetId, item.id!);
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
    String budgetId,
    List<ObservationPdf> comments,
  ) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final now = DateTime.now();
      final formatted = DateFormat('dd/MM/yyyy').format(now);
      for (final c in comments) {
        await _remote.addComment(userUid, budgetId, {
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
    String budgetId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _commentsCache.containsKey(budgetId)) {
      return Result.ok(_commentsCache[budgetId]!);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _remote.getComments(userUid, budgetId);
      final list = raw.map((e) => ObservationBudget.fromMap(e)).toList();
      _commentsCache[budgetId] = list;
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<ItemsBudget>>> fetchBudgetItems(
    String budgetId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _itemsCache.containsKey(budgetId)) {
      return Result.ok(_itemsCache[budgetId]!);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _remote.getBudgetItems(userUid, budgetId);
      final list = raw.map((e) => ItemsBudget.fromMap(e)).toList();
      _itemsCache[budgetId] = list;
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<CustomerInfo>>> fetchBudgetsByMonthRange(
    String startId,
    String endId,
  ) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _remote.getBudgetsByMonthRange(userUid, startId, endId);
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
