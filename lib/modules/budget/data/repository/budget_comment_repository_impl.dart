import 'package:intl/intl.dart';
import 'package:oflite/modules/budget/data/datasource/budget_comment_remote_datasource.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class BudgetCommentRepositoryImpl extends BudgetCommentRepository {
  final BudgetCommentRemoteDatasource _remote;
  final UserRepository _userRepository;

  BudgetCommentRepositoryImpl(this._remote, this._userRepository);

  String? get _userUid => _userRepository.selectUser.value?.user;

  final Map<String, List<ObservationBudget>> _cache = {};

  @override
  List<ObservationBudget> getComments(String budgetId) =>
      List.unmodifiable(_cache[budgetId] ?? []);

  @override
  Future<Result<List<ObservationBudget>>> fetchComments(
    String budgetId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(budgetId)) {
      return Result.ok(_cache[budgetId]!);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _remote.getComments(userUid, budgetId);
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
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final now = DateTime.now();
      final formatted = DateFormat('dd/MM/yyyy').format(now);
      await _remote.addComment(userUid, budgetId, {
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
    String budgetId,
    ObservationBudget comment,
  ) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      if (comment.id == null) {
        return Result.error(Exception('Comment id is null'));
      }
      await _remote.updateComment(userUid, budgetId, comment.id!, {
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
    String budgetId,
    List<ObservationBudget> comments,
  ) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      for (final c in comments) {
        if (c.id != null) {
          await _remote.deleteComment(userUid, budgetId, c.id!);
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
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      await _remote.deleteComment(userUid, budgetId, commentId);
      _cache.remove(budgetId);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
