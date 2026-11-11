import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_payment_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_payment_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class BudgetPaymentRepositoryImpl extends ReceiptPaymentRepository {
  final ReceiptPaymentRemoteDatasource _remote;
  final ReceiptRemoteDatasource _receiptRemote;
  final UserRepository _userRepository;

  BudgetPaymentRepositoryImpl(
    this._remote,
    this._receiptRemote,
    this._userRepository,
  );

  String? get _userUid => _userRepository.selectUser.value?.user;

  List<PaymentCustomer> _payments = [];
  String? _budgetId;
  String? _receiptId;
  String? _lastBudgetId;
  String? _lastReceiptId;

  @override
  List<PaymentCustomer> get payments => List.unmodifiable(_payments);

  @override
  String? get budgetId => _budgetId;

  @override
  set budgetId(String? value) {
    if (value != _budgetId) {
      _budgetId = value;
      _payments = [];
    }
  }

  @override
  String? get receiptId => _receiptId;

  @override
  set receiptId(String? value) {
    if (value != _receiptId) {
      _receiptId = value;
      _payments = [];
    }
  }

  @override
  double get totalPaid {
    double total = 0;
    for (final p in _payments) {
      total += p.price ?? 0;
    }
    return total;
  }

  @override
  Future<Result<List<PaymentCustomer>>> fetchPayments(
    Receipt receipt, {
    bool forceRefresh = false,
  }) async {
    // Evita caminho inválido no Firestore
    if (receipt.id == null ||
        receipt.id!.isEmpty ||
        _budgetId == null ||
        _budgetId!.isEmpty) {
      _payments = [];
      return Result.ok(_payments);
    }

    if (!forceRefresh &&
        _payments.isNotEmpty &&
        _lastBudgetId == _budgetId &&
        _lastReceiptId == _receiptId) {
      return Result.ok(_payments);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _remote.getPayments(userUid, _budgetId!, receipt.id!);
      _payments = raw.map((e) => PaymentCustomer.fromMap(e)).toList();

      // Atualiza valorTotal do receipt se divergir (preserva comportamento original)
      final total = totalPaid;
      if (receipt.valorTotal != total) {
        final updated = receipt.copyWith(valorTotal: total);
        await _receiptRemote.saveReceipt(
          userUid,
          _budgetId!,
          updated.toJson(),
          updated.id!,
        );
      }

      _lastBudgetId = _budgetId;
      _lastReceiptId = _receiptId;
      notifyListeners();
      return Result.ok(_payments);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> savePayment(PaymentCustomer payment) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      if (_budgetId == null || _receiptId == null) {
        return Result.error(Exception('budgetId or receiptId is not set'));
      }
      await _remote.savePayment(
        userUid,
        _budgetId!,
        _receiptId!,
        payment.toMap(),
      );
      _payments.add(payment);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updatePayment(PaymentCustomer payment) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      if (payment.id == null || _budgetId == null || _receiptId == null) {
        return Result.error(Exception('missing id or context'));
      }
      await _remote.updatePayment(
        userUid,
        _budgetId!,
        _receiptId!,
        payment.id!,
        payment.toMap(),
      );
      final index = _payments.indexWhere((p) => p.id == payment.id);
      if (index >= 0) {
        _payments[index] = payment;
        notifyListeners();
      }
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deletePayment(String id) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      if (_budgetId == null || _receiptId == null) {
        return Result.error(Exception('budgetId or receiptId is not set'));
      }
      await _remote.deletePayment(userUid, _budgetId!, _receiptId!, id);
      _payments.removeWhere((p) => p.id == id);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deletePayments(List<PaymentCustomer> payments) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      for (final p in payments) {
        if (p.id != null && _budgetId != null && _receiptId != null) {
          await _remote.deletePayment(userUid, _budgetId!, _receiptId!, p.id!);
        }
      }
      _payments.removeWhere((p) => payments.any((d) => d.id == p.id));
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
