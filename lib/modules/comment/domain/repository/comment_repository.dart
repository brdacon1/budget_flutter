import 'package:flutter/foundation.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class CommentRepository extends ChangeNotifier {
  List<ObservationBudget> getComments(String budgetId);

  Future<Result<List<ObservationBudget>>> fetchComments(String budgetId,
      {bool forceRefresh = false});
  Future<Result<void>> addComment(String budgetId, String text);
  Future<Result<void>> updateComment(
      String budgetId, ObservationBudget comment);
  Future<Result<void>> deleteComments(
      String budgetId, List<ObservationBudget> comments);
  Future<Result<void>> deleteComment(String budgetId, String commentId);
}
