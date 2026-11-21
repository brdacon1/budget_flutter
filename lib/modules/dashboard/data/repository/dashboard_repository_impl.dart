import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:oflite/modules/dashboard/domain/repository/dashboard_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDatasource _remote;
  final UserRepository _user;

  DashboardRepositoryImpl(this._remote, this._user);

  /// Cache curto por mês: trocar de mês e voltar não relê os itens.
  static const _ttl = Duration(minutes: 1);
  final Map<String, ({DateTime at, List<DashboardItemRaw> list})> _cache = {};

  @override
  Future<Result<List<DashboardItemRaw>>> fetchMonthItems(
    String startId,
    String endId,
    List<String> budgetIds, {
    bool forceRefresh = false,
  }) async {
    final uid = _user.selectUser.value?.user;
    if (uid == null || uid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    final key = '$uid|$startId|$endId';
    final hit = _cache[key];
    if (!forceRefresh &&
        hit != null &&
        DateTime.now().difference(hit.at) < _ttl) {
      return Result.ok(hit.list);
    }
    try {
      final raw = await _remote.monthItems(uid, startId, endId, budgetIds);
      final list = [
        for (final i in raw)
          (
            budgetId: i['budgetId'] as String?,
            category: i['CATEGORIA'] as String?,
            quantity: _toDouble(i['QTD']),
            total: _toDouble(i['TOTAL']),
          ),
      ];
      _cache[key] = (at: DateTime.now(), list: list);
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  static double _toDouble(dynamic v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s.replaceAll(',', '.')) ?? 0,
    _ => 0,
  };
}
