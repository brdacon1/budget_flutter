import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_filter.dart';
import 'package:oflite/modules/budget/domain/entity/budget_page.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Lista orçamentos **paginados** (mais novos primeiro), por cursor.
///
/// - Sem nome do cliente: lê o Firestore por ID decrescente, [pageSize] por
///   vez, e filtra o status em memória (sem índice composto). Se uma página
///   não traz nenhum orçamento do status, lê a próxima, até [maxReadsPerCall]
///   leituras por chamada — `hasMore` continua true e quem chama pede mais.
/// - Com nome do cliente: busca por prefixo (limitada a 100 no banco) via
///   [ListBudgetsUsecase], numa página só.
///
/// Não usa nem altera o cache paginado da lista principal de orçamentos.
class ListBudgetsPageUsecase {
  final BudgetRepository _repo;
  final ListBudgetsUsecase _search;

  const ListBudgetsPageUsecase(this._repo, this._search);

  static const pageSize = 20;
  static const maxReadsPerCall = 5;

  Future<Result<BudgetPage>> call(BudgetFilter filter, {String? cursor}) async {
    if ((filter.clientName ?? '').trim().isNotEmpty) {
      if (cursor != null) {
        return const Result.ok(
          BudgetPage(items: [], cursor: null, hasMore: false),
        );
      }
      final result = await _search(filter);
      return switch (result) {
        Ok(:final value) => Result.ok(
          BudgetPage(items: value, cursor: null, hasMore: false),
        ),
        Error(:final error) => Result.error(error),
      };
    }

    final items = <CustomerInfo>[];
    var current = cursor;
    var hasMore = true;
    for (var read = 0; read < maxReadsPerCall && hasMore; read++) {
      final result = await _repo.fetchBudgetsPage(
        limit: pageSize,
        startAfterId: current,
      );
      if (result is Error<List<CustomerInfo>>) {
        return Result.error(result.error);
      }
      final raw = (result as Ok<List<CustomerInfo>>).value;
      if (raw.isEmpty) {
        hasMore = false;
        break;
      }
      current = raw.last.id;
      hasMore = raw.length == pageSize;
      items.addAll(
        raw.where(
          (b) =>
              filter.status == null ||
              b.status?.toUpperCase() == filter.status!.value,
        ),
      );
      if (items.length >= pageSize) break;
    }
    return Result.ok(
      BudgetPage(items: items, cursor: current, hasMore: hasMore),
    );
  }
}
