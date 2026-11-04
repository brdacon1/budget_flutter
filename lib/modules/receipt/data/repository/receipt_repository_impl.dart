import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class ReceiptRepositoryImpl extends ReceiptRepository {
  final ReceiptRemoteDataSource _remote;
  final UserRepository _userRepository;
  ReceiptRepositoryImpl(this._remote, this._userRepository);

  String? get _userUid => _userRepository.selectUser.value?.USER;

  List<Receipt> _receipts = [];
  String? _budgetId;
  String? _lastBudgetId;

  @override
  List<Receipt> get receipts => List.unmodifiable(_receipts);

  @override
  String? get budgetId => _budgetId;
  @override
  set budgetId(String? value) {
    if (value != _budgetId) {
      _budgetId = value;
      _receipts = [];
    }
  }

  @override
  Future<Result<List<Receipt>>> fetchReceipts({bool forceRefresh = false}) async {
    if (_budgetId == null || _budgetId!.isEmpty) {
      _receipts = [];
      return Result.ok(_receipts);
    }
    if (!forceRefresh && _receipts.isNotEmpty && _lastBudgetId == _budgetId) {
      return Result.ok(_receipts);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _remote.getReceipts(userUid, _budgetId!);
      _receipts = raw.map((e) => Receipt.fromJson(e)).toList();
      _lastBudgetId = _budgetId;
      notifyListeners();
      return Result.ok(_receipts);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveReceipt(Receipt receipt) async {
    if (_budgetId == null || _budgetId!.isEmpty) {
      return Result.error(Exception('budgetId is not set'));
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      await _remote.saveReceipt(userUid, _budgetId!, receipt.toJson(), receipt.id!);
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
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      if (receipt.id != null && _budgetId != null) {
        await _remote.deleteReceipt(userUid, _budgetId!, receipt.id!);
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
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      for (final r in receipts) {
        if (r.id != null && _budgetId != null) {
          await _remote.deleteReceipt(userUid, _budgetId!, r.id!);
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
