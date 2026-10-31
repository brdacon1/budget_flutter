import 'package:flutter/foundation.dart';
import 'package:oflite/modules/payment/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class PaymentRepository extends ChangeNotifier {
  List<PaymentCustomer> get payments;
  double get totalPaid;

  Future<Result<List<PaymentCustomer>>> fetchPayments(Receipt receipt,
      {bool forceRefresh = false});
  Future<Result<void>> savePayment(PaymentCustomer payment);
  Future<Result<void>> updatePayment(PaymentCustomer payment);
  Future<Result<void>> deletePayment(String id);
  Future<Result<void>> deletePayments(List<PaymentCustomer> payments);
}
