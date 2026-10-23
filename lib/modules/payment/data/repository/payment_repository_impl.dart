import 'package:oflite/modules/payment/data/datasource/payment_remote_datasource.dart';
import 'package:oflite/modules/payment/domain/repository/payment_repository.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';
import 'package:oflite/shared/models/payment_customer.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PaymentRepositoryImpl extends PaymentRepository {
  final PaymentRemoteDataSource _remote;
  final ReceiptRemoteDataSource _receiptRemote;

  PaymentRepositoryImpl(this._remote, this._receiptRemote);

  List<PaymentCustomer> _payments = [];

  @override
  List<PaymentCustomer> get payments => List.unmodifiable(_payments);

  @override
  double get totalPaid {
    double total = 0;
    for (final p in _payments) {
      total += p.PRECO ?? 0;
    }
    return total;
  }

  @override
  Future<Result<List<PaymentCustomer>>> fetchPayments(Receipt receipt,
      {bool forceRefresh = false}) async {
    // Evita caminho inválido no Firestore
    if (receipt.id == null ||
        receipt.id!.isEmpty) {
      _payments = [];
      return Result.ok(_payments);
    }

    if (!forceRefresh && _payments.isNotEmpty) {
      return Result.ok(_payments);
    }
    try {
      final raw = await _remote.getPayments();
      _payments = raw.map((e) => PaymentCustomer.fromMap(e)).toList();

      // Atualiza valorTotal do receipt se divergir (preserva comportamento original)
      final total = totalPaid;
      if (receipt.valorTotal != total) {
        final updated = receipt.copyWith(valorTotal: total);
        await _receiptRemote.saveReceipt(updated.toJson(), updated.id!);
      }

      notifyListeners();
      return Result.ok(_payments);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> savePayment(PaymentCustomer payment) async {
    try {
      await _remote.savePayment(payment.toMap());
      _payments.add(payment);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updatePayment(PaymentCustomer payment) async {
    try {
      if (payment.id == null) {
        return Result.error(Exception('Payment id is null'));
      }
      await _remote.updatePayment(payment.id!, payment.toMap());
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
    try {
      await _remote.deletePayment(id);
      _payments.removeWhere((p) => p.id == id);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deletePayments(List<PaymentCustomer> payments) async {
    try {
      for (final p in payments) {
        if (p.id != null) {
          await _remote.deletePayment(p.id!);
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
