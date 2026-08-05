import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/global_uid_budget.dart' as budget;
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/services/http_request.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
TextEditingController searchController = TextEditingController();

class BudgetListItemsViewModel extends ChangeNotifier {
  var orcamentos = <ItemsBudget>[];
  var deleteItens = <ItemsBudget>[];
  ItemsBudget novo = ItemsBudget();
  ConvertCoin moneyConvert = ConvertCoin();
  var db = HttpRequest();
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  double totalProducts = 0;
  double totalServices = 0;
  double totalBudget = 0;
  int countProduct = 0;
  int countService = 0;

  final CustomerInfo item;

  BudgetListItemsViewModel({required this.item});

  Future<void> getListItens() async {
    orcamentos.clear();
    totalProducts = 0;
    totalServices = 0;
    totalBudget = 0;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(
            "EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${item.id}/ITENS")
        .orderBy('CATEGORIA', descending: false)
        .get();
    List<QueryDocumentSnapshot> documents = querySnapshot.docs;
    for (var document in documents) {
      Map<String, dynamic> data = document.data() as Map<String, dynamic>;
      ItemsBudget item = ItemsBudget.fromMap(data);
      item.checkBox = false;
      item.id = document.id; // Obter o doc.id e atribuir ao item.id
      orcamentos.add(item);
    }
    for (int index = 0; index < orcamentos.length; index++) {
      double total = orcamentos[index].TOTAL!;
      if (orcamentos[index].CATEGORIA == 'Produtos') {
        totalProducts += total;
        countProduct++;
      } else if (orcamentos[index].CATEGORIA == 'Serviços') {
        totalServices += total;
        countService++;
      }
      totalBudget += total;
    }
    if (budget.VALORTOTAL != totalBudget) {
      budget.VALORTOTAL = totalBudget;
      await db.updateItemsDADOS();
    }

    notifyListeners();
  }

  Future<bool> deleteData() async {
    bool result = false;

    for (int i = 0; i < deleteItens.length; i++) {
      await FirebaseFirestore.instance
          .collection(
              "EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${item.id}/ITENS")
          .doc(deleteItens[i].id)
          .delete();
    }
    result = true;
    return result;
  }

  void onSearchTextChanged(String value) {
    notifyListeners();
  }

  List<ItemsBudget> getFilteredData() {
    if (searchController.text.isEmpty) {
      return orcamentos; // Retorna a lista original se não houver texto de busca
    } else {
      return orcamentos
          .where((x) => x.DESCRICAO!
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList(); // Filtra a lista original com base no texto de busca
    }
  }

  void toggleDeleteItem(int index) {
    if (!getFilteredData()[index].checkBox!) {
      getFilteredData()[index].checkBox = true;
      getFilteredData()[index].selectProduct = false;
      getFilteredData()[index].indice = index;
      deleteItens.add(getFilteredData()[index]);
      if (deleteItens.isNotEmpty) {
        deleteVisible = true;
      }
    }
    notifyListeners();
  }

  void removeDeleteItem(ItemsBudget item) {
    getFilteredData()[item.indice].checkBox = false;
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
}
