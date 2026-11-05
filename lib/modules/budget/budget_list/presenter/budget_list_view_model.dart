import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

TextEditingController searchController = TextEditingController();

class BudgetListViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final DisplayAlertRepository displayAlert = getIt<DisplayAlertRepository>();

  bool _disposed = false;

  BudgetListViewModel() {
    _budgetRepository.addListener(_onBudgetRepoChanged);
  }

  CustomerInfo customerBudget = CustomerInfo();
  final _foundUsers = <CustomerInfo>[];
  final deleteItems = <CustomerInfo>[];
  CustomerInfo _customerInfoNew = CustomerInfo();

  bool deleteVisible = false;
  bool checkBoxAppear = false;
  bool _isRefreshing = false;

  int _totalBudgetCount = 0;
  int get totalBudgetCount => _totalBudgetCount;

  Future<void> loadCount() async {
    final result = await _budgetRepository.countBudgets();
    if (result is Ok<int>) {
      _totalBudgetCount = result.value;
      if (!_disposed) notifyListeners();
    }
  }

  bool get isLoadingMore => _budgetRepository.isLoadingMoreBudgets;
  bool get hasMoreBudgets => _budgetRepository.hasMoreBudgets;

  Future<void> loadMore() async {
    if (_isRefreshing || !hasMoreBudgets) return;
    await getInformationOrcamento(refresh: false);
  }

  void _onBudgetRepoChanged() {
    if (_disposed || _isRefreshing) return;
    getInformationOrcamento(refresh: false);
  }

  Future<void> initialScreen() async {
    await loadCount();
    await getInformationOrcamento(refresh: true);
  }

  Future<void> duplicateEvent(
    bool clientData,
    bool quoteItems,
    bool comments,
  ) async {
    final String? originalId = _budgetRepository.selectBudget.value?.id;
    if (originalId == null || originalId.isEmpty) return;

    final result = await _budgetRepository.duplicateBudget(
      sourceId: originalId,
      copyClientData: clientData,
      copyItems: quoteItems,
      copyComments: comments,
    );

    if (result is Ok<CustomerInfo>) {
      customerBudget = result.value;
      _budgetRepository.clearSelectBudget();
      _totalBudgetCount++;
      if (!_disposed) notifyListeners();
      await getInformationOrcamento(refresh: true);
    }
  }

  Future<bool> deleteData() async {
    final result = await _budgetRepository.deleteBudgets(deleteItems);
    if (result is Ok<void>) {
      _totalBudgetCount -= deleteItems.length;
      if (!_disposed) notifyListeners();
      deleteItems.clear();
      deleteVisible = false;
      await getInformationOrcamento(refresh: true);
      return true;
    }
    return false;
  }

  Future<List<CustomerInfo>> getInformationOrcamento(
      {bool refresh = true}) async {
    _isRefreshing = true;
    final result =
        await _budgetRepository.fetchBudgetsPaginated(refresh: refresh);
    _foundUsers.clear();
    if (result is Ok<List<CustomerInfo>>) {
      for (final b in result.value) {
        b.checkBox = false;
        _foundUsers.add(b);
      }
    }
    _isRefreshing = false;
    if (!_disposed) notifyListeners();
    return _foundUsers;
  }

  void onSearchTextChanged(String value) {
    if (!_disposed) notifyListeners();
  }

  List<CustomerInfo> getFilteredData() {
    if (searchController.text.isEmpty) {
      return _foundUsers;
    } else {
      return _foundUsers
          .where(
            (x) => x.customerName!.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }
  }

  void toggleDeleteItem(int index) {
    if (!getFilteredData()[index].checkBox!) {
      getFilteredData()[index].checkBox = true;
      getFilteredData()[index].index = index;
      deleteItems.add(getFilteredData()[index]);
      if (deleteItems.isNotEmpty) {
        deleteVisible = true;
      }
    }
    if (!_disposed) notifyListeners();
  }

  void removeDeleteItem(CustomerInfo item) {
    getFilteredData()[item.index].checkBox = false;
    deleteItems.remove(item);
    if (deleteItems.isEmpty) {
      deleteVisible = false;
      checkBoxAppear = false;
    }
    if (!_disposed) notifyListeners();
  }

  void clearDeleteItens() {
    deleteItems.clear();
    deleteVisible = false;
    checkBoxAppear = false;
    if (!_disposed) notifyListeners();
  }

  CustomerInfo customerInfoNew() {
    _customerInfoNew = CustomerInfo(
      phone: '',
      customerName: '',
      address: '',
      email: '',
      generated: '',
      data: '',
      status: 'PENDENTE',
      zip: '',
      city: '',
      neighborhood: '',
      id: '',
      street: '',
    );
    _budgetRepository.clearSelectBudget();
    return _customerInfoNew;
  }

  @override
  void dispose() {
    _disposed = true;
    _budgetRepository.removeListener(_onBudgetRepoChanged);
    super.dispose();
  }
}
