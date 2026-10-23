import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/observation_budget.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as UID;

class CommentListViewModel extends ChangeNotifier {
  CommentListViewModel({required this.item});

  final CustomerInfo item;

  List<ObservationBudget> observation = <ObservationBudget>[];
  List<ObservationBudget> foundObservation = <ObservationBudget>[];
  List<ObservationBudget> deleteItems = <ObservationBudget>[];

  bool deleteVisible = false;
  bool checkBoxAppear = false;

  String _collectionPath() =>
      "EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${item.id}/OBSERVACAO";

  /// Carrega (ou recarrega) a lista de comentários do orçamento.
  Future<bool> loadComments() async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionPath())
          .get();

      observation.clear();
      querySnapshot.docs.map<ObservationBudget>((doc) {
        final objectComment = ObservationBudget.fromMap(doc.data()!);
        objectComment.id = doc.id;
        objectComment.checkbox = false;
        observation.add(objectComment);
        return objectComment;
      }).toList();

      foundObservation = List<ObservationBudget>.from(observation);
      notifyListeners();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Adiciona um novo comentário.
  Future<bool> addComment(String text) async {
    try {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);

      await FirebaseFirestore.instance
          .collection(_collectionPath())
          .doc()
          .set({'OBSERVACAO': text, 'DATA': formatted});
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Atualiza um comentário existente.
  Future<bool> updateComment(ObservationBudget updateObservation) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collectionPath())
          .doc(updateObservation.id)
          .update({
        'OBSERVACAO': updateObservation.observacao,
        'DATA': updateObservation.data
      });
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Exclui os comentários marcados em [deleteItems].
  Future<bool> deleteSelected() async {
    try {
      if (deleteItems.isEmpty) return true;

      final int count = deleteItems.length - 1;
      for (int i = 0; i < deleteItems.length; i++) {
        await FirebaseFirestore.instance
            .collection(_collectionPath())
            .doc(deleteItems[i].id)
            .delete()
            .then((value) async {
          if (i == count) {
            deleteItems.clear();
            deleteVisible = false;
            checkBoxAppear = false;
            await loadComments();
          }
        });
      }
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Exclui um único comentário.
  Future<bool> deleteComment(ObservationBudget comment) async {
    deleteItems.add(comment);
    final result = await deleteSelected();
    deleteItems.clear();
    deleteVisible = false;
    checkBoxAppear = false;
    notifyListeners();
    return result;
  }

  /// Reseta o estado de seleção/exclusão múltipla.
  void resetSelectionState() {
    deleteItems.clear();
    deleteVisible = false;
    checkBoxAppear = false;
    notifyListeners();
  }
}
