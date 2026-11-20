import 'package:flutter/foundation.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/budget/data/datasource/budget_metrics_remote_datasource.dart';
import 'package:oflite/modules/budget/domain/repository/budget_metrics_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class BudgetMetricsRepositoryImpl implements BudgetMetricsRepository {
  final BudgetMetricsRemoteDatasource _remote;
  final UserRepository _userRepository;

  BudgetMetricsRepositoryImpl(this._remote, this._userRepository);

  @override
  Future<Result<BudgetMetricsRaw>> fetch(String budgetId) async {
    final uid = _userRepository.selectUser.value?.user;
    if (uid == null || uid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final (items, receipts, proofs, payments) =
          await (
            _remote.items(uid, budgetId),
            _remote.receiptsCount(uid, budgetId),
            _remote.proofsSummary(uid, budgetId),
            _remote.budgetPayments(uid, budgetId),
          ).wait;
      return Result.ok((
        items: [
          for (final i in items)
            (category: i['CATEGORIA'] as String?, total: _toDouble(i['TOTAL'])),
        ],
        receiptsCount: receipts,
        proofsCount: proofs.count,
        proofsTotal: proofs.total,
        payments: [
          for (final p in payments)
            (method: p['METODO'] as String?, price: _toDouble(p['PRECO'])),
        ],
      ));
    } catch (e) {
      debugPrint('[BudgetMetrics] erro: $e');
      return Result.error(Exception(e.toString()));
    }
  }

  static double _toDouble(dynamic v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };
}
