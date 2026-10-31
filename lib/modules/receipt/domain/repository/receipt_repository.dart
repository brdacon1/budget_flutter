import 'package:flutter/foundation.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class ReceiptRepository extends ChangeNotifier {
  List<Receipt> get receipts;

  Future<Result<List<Receipt>>> fetchReceipts({bool forceRefresh = false});
  Future<Result<void>> saveReceipt(Receipt receipt);
  Future<Result<void>> deleteReceipt(Receipt receipt);
  Future<Result<void>> deleteReceipts(List<Receipt> receipts);
}
