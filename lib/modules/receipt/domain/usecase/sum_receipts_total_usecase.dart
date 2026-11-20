import 'package:oflite/modules/receipt/data/model/receipt.dart';

/// Soma o valor total (`valorTotal`) dos recibos gerados no orçamento.
class SumReceiptsTotalUsecase {
  const SumReceiptsTotalUsecase();

  double call(Iterable<Receipt> receipts) =>
      receipts.fold(0.0, (sum, r) => sum + (r.valorTotal ?? 0));
}
