import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_filter.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Lista orçamentos por período, status e nome do cliente.
///
/// O ID do orçamento é o timestamp (ms) de criação: o período vira um range
/// de IDs consultado direto no Firestore. Status e cliente filtram em memória.
class ListBudgetsUsecase {
  final BudgetRepository _repo;

  const ListBudgetsUsecase(this._repo);

  Future<Result<List<CustomerInfo>>> call(BudgetFilter filter) async {
    final Result<List<CustomerInfo>> result;
    if (filter.from != null || filter.to != null) {
      final from = filter.from ?? DateTime(2000);
      final to = filter.to ?? DateTime.now();
      final start = DateTime(from.year, from.month, from.day);
      final end = DateTime(
        to.year,
        to.month,
        to.day + 1,
      ).subtract(const Duration(milliseconds: 1));
      result = await _repo.fetchBudgetsByMonthRange(
        start.millisecondsSinceEpoch.toString(),
        end.millisecondsSinceEpoch.toString(),
      );
    } else {
      result = await _repo.fetchBudgets();
    }
    if (result is Error<List<CustomerInfo>>) return result;

    final client = _normalize(filter.clientName ?? '');
    final list =
        (result as Ok<List<CustomerInfo>>).value.where((b) {
            if (filter.status != null &&
                b.status?.toUpperCase() != filter.status!.value) {
              return false;
            }
            if (client.isNotEmpty &&
                !_normalize(b.customerName ?? '').contains(client)) {
              return false;
            }
            return true;
          }).toList()
          ..sort((a, b) => (b.id ?? '').compareTo(a.id ?? ''));
    return Result.ok(list);
  }

  static String _normalize(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final lower = s.toLowerCase().trim();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf.toString();
  }
}
