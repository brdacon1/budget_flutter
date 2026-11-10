import 'package:flutter/foundation.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class ReceiptPaymentRepository extends ChangeNotifier {
  List<PaymentCustomer> get payments;

  double get totalPaid;

  String? get budgetId;

  set budgetId(String? value);

  String? get receiptId;

  set receiptId(String? value);

  Future<Result<List<PaymentCustomer>>> fetchPayments(
    Receipt receipt, {
    bool forceRefresh = false,
  });

  Future<Result<void>> savePayment(PaymentCustomer payment);

  Future<Result<void>> updatePayment(PaymentCustomer payment);

  Future<Result<void>> deletePayment(String id);

  Future<Result<void>> deletePayments(List<PaymentCustomer> payments);
}
