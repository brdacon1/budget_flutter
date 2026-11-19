import 'package:oflite/modules/receipt/domain/entity/receipt_ledger.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Leitura de todos os recibos + pagamentos do usuário (só leitura).
/// Não usa nem altera o `budgetId`/`receiptId` compartilhado das telas.
abstract class ReceiptLedgerRepository {
  Future<Result<ReceiptLedger>> fetchLedger({bool forceRefresh = false});

  /// Descarta o cache (ex.: após criar um recibo).
  void invalidate();
}
