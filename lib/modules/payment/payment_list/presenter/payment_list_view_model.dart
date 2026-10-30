import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/payment/domain/repository/payment_repository.dart';
import 'package:oflite/modules/payment/payment_creator/presenter/payment_creator_view.dart';
import 'package:oflite/modules/payment/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as Orcamento;
import 'package:oflite/shared/models/payment_customer.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PaymentListViewModel extends ChangeNotifier {
  final PaymentRepository _paymentRepository;
  final DisplayAlertRepository _displayAlert;
  final LoadingEventRepository _loadingEvent;
  final ConvertCoinRepository _moneyConvert;

  final CustomerInfo item;
  final Receipt receipt;

  List<PaymentCustomer> foundPayment = <PaymentCustomer>[];
  double totalPaid = 0;

  PaymentListViewModel({
    required this.item,
    required this.receipt,
    PaymentRepository? paymentRepository,
    DisplayAlertRepository? displayAlertRepository,
    LoadingEventRepository? loadingEventRepository,
    ConvertCoinRepository? convertCoinRepository,
  })  : _paymentRepository = paymentRepository ?? getIt<PaymentRepository>(),
        _displayAlert = displayAlertRepository ?? getIt<DisplayAlertRepository>(),
        _loadingEvent = loadingEventRepository ?? getIt<LoadingEventRepository>(),
        _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>();

  ConvertCoinRepository get moneyConvert => _moneyConvert;

  Future<void> inicialData() async {
    // Path do Firestore depende das globais budget.IDORCAMENTO e budget.IDRECIBO.
    Orcamento.IDORCAMENTO = item.id;
    Orcamento.IDRECIBO = receipt.id;
    final result = await _paymentRepository.fetchPayments(receipt);
    if (result is Ok<List<PaymentCustomer>>) {
      foundPayment = result.value;
    }
    _calcTotal();
    notifyListeners();
  }

  void _calcTotal() {
    totalPaid = _paymentRepository.totalPaid;
  }

  Future<void> refresh() => inicialData();

  Future<void> deletePayment(BuildContext context, int index) async {
    _loadingEvent.alertLoading(context);
    try {
      final result =
          await _paymentRepository.deletePayment(foundPayment[index].id!);
      _loadingEvent.closeLoading(context);
      if (result is Ok<void>) {
        await _displayAlert.notificationNotCloseScreen(
            context, PaymentStrings.doneTitle, PaymentStrings.paymentRemoved);
      }
    } catch (e) {
      _loadingEvent.closeLoading(context);
      await _displayAlert.notificationError(
          context, PaymentStrings.errorTitle, PaymentStrings.errorRemovePayment);
    }
    await inicialData();
  }

  Future<void> editPayment(BuildContext context, int index) async {
    Orcamento.IDRECIBO = receipt.id;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PaymentCreatorView(item: foundPayment[index])),
    );
    await inicialData();
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
    final PaymentCustomer novo = PaymentCustomer()
      ..METODO = ''
      ..id = ''
      ..DESCRICAO = 'null'
      ..PRECO = 0;
    Orcamento.IDRECIBO = receipt.id;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentCreatorView(item: novo)),
    );
    await inicialData();
  }
}
