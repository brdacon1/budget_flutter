import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class ReceiptRepositoryImpl extends ReceiptRepository {
  final ReceiptRemoteDataSource _remote;
  ReceiptRepositoryImpl(this._remote);

  List<Receipt> _receipts = [];

  @override
  List<Receipt> get receipts => List.unmodifiable(_receipts);

  @override
  Future<Result<List<Receipt>>> fetchReceipts({bool forceRefresh = false}) async {
    if (!forceRefresh && _receipts.isNotEmpty) {
      return Result.ok(_receipts);
    }
    try {
      final raw = await _remote.getReceipts();
      _receipts = raw.map((e) => Receipt.fromJson(e)).toList();
      notifyListeners();
      return Result.ok(_receipts);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveReceipt(Receipt receipt) async {
    try {
      await _remote.saveReceipt(receipt.toJson(), receipt.id!);
      final index = _receipts.indexWhere((r) => r.id == receipt.id);
      if (index >= 0) {
        _receipts[index] = receipt;
      } else {
        _receipts.add(receipt);
      }
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteReceipt(Receipt receipt) async {
    try {
      if (receipt.id != null) {
        await _remote.deleteReceipt(receipt.id!);
        _receipts.removeWhere((r) => r.id == receipt.id);
        notifyListeners();
      }
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteReceipts(List<Receipt> receipts) async {
    try {
      for (final r in receipts) {
        if (r.id != null) {
          await _remote.deleteReceipt(r.id!);
        }
      }
      _receipts.removeWhere((r) => receipts.any((d) => d.id == r.id));
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
