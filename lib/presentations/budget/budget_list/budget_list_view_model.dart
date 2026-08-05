import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/global_uid_budget.dart' as budget;
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/http_request.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
TextEditingController searchController = TextEditingController();

class BudgetListViewModel extends ChangeNotifier {
  CustomerInfo customerBudget = CustomerInfo();
  Color enabled = const Color(0xFF827F8A);
  final _foundUsers = <CustomerInfo>[];
  final deleteItens = <CustomerInfo>[];
  CustomerInfo novo = CustomerInfo();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  var displayAlert = DisplayAlert();

  Future<void> initialScreen() async {
    await getInformationOrcamento();
    notifyListeners();
  }

  Future<void> duplicateEvent(
      bool clientData, bool quoteItems, bool comments) async {
    var db = HttpRequest();
    String? originalId = budget.IDORCAMENTO;
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String formatted = formatter.format(now);

    customerBudget = CustomerInfo();

    if (clientData) {
      final value = await db.getInformationOrcamento1();
      if (value.customerName?.isNotEmpty ?? false) {
        customerBudget.customerName = value.customerName;
        customerBudget.phone = value.phone;
        customerBudget.status = value.status;
        customerBudget.email = value.email;
        customerBudget.address = value.address;
        customerBudget.generated = value.generated;
        customerBudget.companyName = value.companyName;
        customerBudget.zip = value.zip;
        customerBudget.street = value.street;
        customerBudget.city = value.city;
        customerBudget.neighborhood = value.neighborhood;
        customerBudget.totalValue = value.totalValue;
      }
    } else {
      customerBudget.customerName = "Duplicado de: ${originalId}";
      customerBudget.phone = "";
      customerBudget.status = "";
      customerBudget.email = "";
      customerBudget.address = "";
      customerBudget.generated = "";
      customerBudget.companyName = "";
      customerBudget.zip = "";
      customerBudget.street = "";
      customerBudget.city = "";
      customerBudget.neighborhood = "";
    }

    customerBudget.data = formatted;
    customerBudget.id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.saveBudget(customerBudget);

    if (quoteItems) {
      final quoteItemsObject = await db.getListItemsGenerator(originalId);
      if (quoteItemsObject.isNotEmpty) {
        await db.saveItemsList(quoteItemsObject);
      }
    }

    if (comments) {
      final commentsObject = await db.getListComment(originalId);
      if (commentsObject.isNotEmpty) {
        await db.addComment(commentsObject);
      }
    }

    budget.IDORCAMENTO = '';
    notifyListeners();
  }

  Future<bool> deleteData() async {
    bool result = false;
    int count = deleteItens.length - 1;
    for (int i = 0; i < deleteItens.length; i++) {
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
          .doc(deleteItens[i].id)
          .delete()
          .then((value) async {
        if (i == count) {
          deleteItens.clear();
          deleteVisible = false;
          await getInformationOrcamento();
          notifyListeners();
        }
      });
    }
    return result;
  }

  Future<List<CustomerInfo>> getInformationOrcamento() async {
    int index = 0;
    _foundUsers.clear();

    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
        .orderBy('ID', descending: true)
        .get();

    for (var questionTmp in querySnapshot.docs) {
      final data = questionTmp.data();
      _foundUsers.add(CustomerInfo.fromMap(data));
      _foundUsers[index].checkBox = false;
      index++;
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
    novo.phone = '';
    novo.customerName = '';
    novo.companyName = '';
    novo.address = '';
    novo.email = '';
    novo.generated = '';
    novo.data = '';
    novo.status = 'PENDENTE';
    novo.zip = '';
    novo.city = '';
    novo.neighborhood = '';
    novo.id = '';
    novo.street = '';
    budget.IDORCAMENTO = '';
    return novo;
  }
}
