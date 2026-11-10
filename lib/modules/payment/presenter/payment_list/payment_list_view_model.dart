import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/payment/data/model/payment_customer.dart';
import 'package:oflite/modules/payment/domain/repository/payment_repository.dart';
import 'package:oflite/modules/payment/presenter/payment_creator/payment_creator_view.dart';
import 'package:oflite/modules/payment/presenter/strings/payment_pt_string.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PaymentListViewModel extends ChangeNotifier {
  final PaymentRepository _paymentRepository;
  final DisplayAlertRepository _displayAlert;
  final ConvertCoinRepository _moneyConvert;
  late final Command1<void, int> deletePaymentCommand = Command1(
    _deletePayment,
  );

  final CustomerInfo item;
  Receipt receipt;

  List<PaymentCustomer> foundPayment = <PaymentCustomer>[];
  double totalPaid = 0;

  PaymentListViewModel({
    required this.item,
    required this.receipt,
    PaymentRepository? paymentRepository,
    DisplayAlertRepository? displayAlertRepository,
    LoadingEventRepository? loadingEventRepository,
    ConvertCoinRepository? convertCoinRepository,
  }) : _paymentRepository = paymentRepository ?? getIt<PaymentRepository>(),
       _displayAlert =
           displayAlertRepository ?? getIt<DisplayAlertRepository>(),
       _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>();

  ConvertCoinRepository get moneyConvert => _moneyConvert;

  Future<void> inicialData({bool forceRefresh = false}) async {
    _paymentRepository.budgetId = item.id;
    _paymentRepository.receiptId = receipt.id;
    final result = await _paymentRepository.fetchPayments(
      receipt,
      forceRefresh: forceRefresh,
    );
    if (result is Ok<List<PaymentCustomer>>) {
      foundPayment = result.value;
    }
    _calcTotal();
    receipt = receipt.copyWith(valorTotal: totalPaid);
    notifyListeners();
  }

  void _calcTotal() {
    totalPaid = _paymentRepository.totalPaid;
  }

  Future<void> refresh() => inicialData(forceRefresh: true);

  Future<Result<void>> _deletePayment(int index) async {
    try {
      await _paymentRepository.deletePayment(foundPayment[index].id!);
      await inicialData(forceRefresh: true);
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  Future<void> editPayment(BuildContext context, int index) async {
    _paymentRepository.receiptId = receipt.id;
    final result = await showPaymentCreatorBottomModal(
      context,
      item: foundPayment[index],
    );
    if (result == true) {
      await inicialData(forceRefresh: true);
    }
  }

  Future<void> addPayment(BuildContext context) async {
    if (receipt.id == null || receipt.id!.isEmpty) {
      await _displayAlert.notificationWarning(
        context,
        PaymentStrings.receiptNotSaved,
        PaymentStrings.receiptNotSavedMessage,
      );
      return;
    }
    final PaymentCustomer novo =
        PaymentCustomer()
          ..method = ''
          ..id = ''
          ..description = 'null'
          ..price = 0;
    _paymentRepository.receiptId = receipt.id;
    final result = await showPaymentCreatorBottomModal(context, item: novo);
    if (result == true) {
      await inicialData(forceRefresh: true);
    }
  }
}
