import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Duplica um orçamento e, opcionalmente, seus recibos e pagamentos.
///
/// Orquestra [BudgetRepository] (orçamento, itens, comentários) e
/// [ReceiptRepository] (recibos e pagamentos).
class DuplicateBudgetUsecase {
  final BudgetRepository _budgetRepo;
  final ReceiptRepository _receiptRepo;

  const DuplicateBudgetUsecase(this._budgetRepo, this._receiptRepo);

  Future<Result<CustomerInfo>> call({
    required String sourceId,
    required bool copyClientData,
    required bool copyItems,
    required bool copyComments,
    required bool copyReceipts,
  }) async {
    final result = await _budgetRepo.duplicateBudget(
      sourceId: sourceId,
      copyClientData: copyClientData,
      copyItems: copyItems,
      copyComments: copyComments,
    );
    if (result is! Ok<CustomerInfo> || !copyReceipts) return result;

    final receipts = await _receiptRepo.duplicateReceipts(
      sourceBudgetId: sourceId,
      targetBudgetId: result.value.id!,
    );
    if (receipts is Error<void>) return Result.error(receipts.error);
    return result;
  }
}
