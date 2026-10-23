import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/comment/domain/repository/comment_repository.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/observation_budget.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class CommentListViewModel extends ChangeNotifier {
  final CommentRepository _commentRepository = getIt<CommentRepository>();

  CommentListViewModel({required this.item});

  final CustomerInfo item;

  List<ObservationBudget> observation = <ObservationBudget>[];
  List<ObservationBudget> foundObservation = <ObservationBudget>[];
  List<ObservationBudget> deleteItems = <ObservationBudget>[];

  bool deleteVisible = false;
  bool checkBoxAppear = false;

  Future<bool> loadComments() async {
    final result = await _commentRepository.fetchComments(item.id!);
    if (result is Ok<List<ObservationBudget>>) {
      observation = List<ObservationBudget>.from(result.value);
      for (final o in observation) {
        o.checkbox = false;
      }
      foundObservation = List<ObservationBudget>.from(observation);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> addComment(String text) async {
    final result = await _commentRepository.addComment(item.id!, text);
    if (result is Ok<void>) {
      await loadComments();
      return true;
    }
    return false;
  }

  Future<bool> updateComment(ObservationBudget updateObservation) async {
    final result =
        await _commentRepository.updateComment(item.id!, updateObservation);
    if (result is Ok<void>) {
      await loadComments();
      return true;
    }
    return false;
  }

  Future<bool> deleteSelected() async {
    final result = await _commentRepository.deleteComments(item.id!, deleteItems);
    if (result is Ok<void>) {
      deleteItems.clear();
      deleteVisible = false;
      checkBoxAppear = false;
      await loadComments();
      return true;
    }
    return false;
  }

  Future<bool> deleteComment(ObservationBudget comment) async {
    deleteItems.add(comment);
    final result = await deleteSelected();
    deleteItems.clear();
    deleteVisible = false;
    checkBoxAppear = false;
    notifyListeners();
    return result;
  }

  void resetSelectionState() {
    deleteItems.clear();
    deleteVisible = false;
    checkBoxAppear = false;
    notifyListeners();
  }
}
