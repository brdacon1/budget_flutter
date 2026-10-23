import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/shared/design_pattern/result.dart';

TextEditingController searchController = TextEditingController();

class BudgetListViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final DisplayAlert displayAlert = DisplayAlert();

  CustomerInfo customerBudget = CustomerInfo();
  Color enabled = const Color(0xFF827F8A);
  final _foundUsers = <CustomerInfo>[];
  final deleteItens = <CustomerInfo>[];
  CustomerInfo novo = CustomerInfo();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool deleteVisible = false;
  bool checkBoxAppear = false;

  Future<void> initialScreen() async {
    await getInformationOrcamento();
  }

  Future<void> duplicateEvent(
      bool clientData, bool quoteItems, bool comments) async {
    final String? originalId = budget.IDORCAMENTO;
    if (originalId == null || originalId.isEmpty) return;

    final result = await _budgetRepository.duplicateBudget(
      sourceId: originalId,
      copyClientData: clientData,
      copyItems: quoteItems,
      copyComments: comments,
    );

    if (result is Ok<CustomerInfo>) {
      customerBudget = result.value;
      budget.IDORCAMENTO = '';
      await getInformationOrcamento();
    }
  }

  Future<bool> deleteData() async {
    final result = await _budgetRepository.deleteBudgets(deleteItens);
    if (result is Ok<void>) {
      deleteItens.clear();
      deleteVisible = false;
      await getInformationOrcamento();
      return true;
    }
    return false;
  }

  Future<List<CustomerInfo>> getInformationOrcamento() async {
    final result = await _budgetRepository.fetchBudgets();
    _foundUsers.clear();
    if (result is Ok<List<CustomerInfo>>) {
      for (final b in result.value) {
        b.checkBox = false;
        _foundUsers.add(b);
      }
    }
    notifyListeners();
    return _foundUsers;
  }

  void onSearchTextChanged(String value) {
    notifyListeners();
  }

  List<CustomerInfo> getFilteredData() {
    if (searchController.text.isEmpty) {
      return _foundUsers;
    } else {
      return _foundUsers
          .where((x) => x.customerName!
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    }
  }

  void toggleDeleteItem(int index) {
    if (!getFilteredData()[index].checkBox!) {
      getFilteredData()[index].checkBox = true;
      getFilteredData()[index].index = index;
      deleteItens.add(getFilteredData()[index]);
      if (deleteItens.isNotEmpty) {
        deleteVisible = true;
      }
    }
    notifyListeners();
  }

  void removeDeleteItem(CustomerInfo item) {
    getFilteredData()[item.index].checkBox = false;
    deleteItens.remove(item);
    if (deleteItens.isEmpty) {
      deleteVisible = false;
      checkBoxAppear = false;
    }
    notifyListeners();
  }

  void clearDeleteItens() {
    deleteItens.clear();
    deleteVisible = false;
    checkBoxAppear = false;
    notifyListeners();
  }

  CustomerInfo novoOrcamento() {
    novo = CustomerInfo(
      phone: '',
      customerName: '',
      companyName: '',
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
    budget.IDORCAMENTO = '';
    return novo;
  }
}
