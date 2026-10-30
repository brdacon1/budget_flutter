import 'package:intl/intl.dart';
import 'package:oflite/modules/comment/data/datasource/comment_remote_datasource.dart';
import 'package:oflite/modules/comment/domain/repository/comment_repository.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class CommentRepositoryImpl extends CommentRepository {
  final CommentRemoteDataSource _remote;
  CommentRepositoryImpl(this._remote);

  final Map<String, List<ObservationBudget>> _cache = {};

  @override
  List<ObservationBudget> getComments(String budgetId) =>
      List.unmodifiable(_cache[budgetId] ?? []);

  @override
  Future<Result<List<ObservationBudget>>> fetchComments(String budgetId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.containsKey(budgetId)) {
      return Result.ok(_cache[budgetId]!);
    }
    try {
      final raw = await _remote.getComments(budgetId);
      final list = raw.map((e) => ObservationBudget.fromMap(e)).toList();
      _cache[budgetId] = list;
      notifyListeners();
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> addComment(String budgetId, String text) async {
    try {
      final now = DateTime.now();
      final formatted = DateFormat('dd/MM/yyyy').format(now);
      await _remote.addComment(budgetId, {
        'OBSERVACAO': text,
        'DATA': formatted,
      });
      _cache.remove(budgetId); // invalida cache
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateComment(
      String budgetId, ObservationBudget comment) async {
    try {
      if (comment.id == null) {
        return Result.error(Exception('Comment id is null'));
      }
      await _remote.updateComment(budgetId, comment.id!, {
        'OBSERVACAO': comment.observacao,
        'DATA': comment.data,
      });
      _cache.remove(budgetId);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteComments(
      String budgetId, List<ObservationBudget> comments) async {
    try {
      for (final c in comments) {
        if (c.id != null) {
          await _remote.deleteComment(budgetId, c.id!);
        }
      }
      _cache.remove(budgetId);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteComment(String budgetId, String commentId) async {
    try {
      await _remote.deleteComment(budgetId, commentId);
      _cache.remove(budgetId);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
