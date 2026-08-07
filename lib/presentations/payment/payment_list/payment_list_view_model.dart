import 'package:flutter/material.dart';
import 'package:oflite/Services/http_request.dart';
import 'package:oflite/models/receipt.dart';
import 'package:oflite/models/global_uid_budget.dart' as Orcamento;
import 'package:oflite/presentations/payment/payment_creator/payment_creator_view.dart';
import '../../../services/convert_coin.dart';
import '../../../models/customer_info.dart';
import '../../../models/payment_customer.dart';
import '../../../Services/display_alert.dart';
import '../../../Services/loading_event.dart';

class PaymentListViewModel extends ChangeNotifier {
  final DisplayAlert displayAlert = DisplayAlert();
  final HttpRequest db = HttpRequest();
  final LoadingEvent loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  final CustomerInfo item;
  final Receipt receipt;

  List<PaymentCustomer> foundPayment = <PaymentCustomer>[];
  double totalPaid = 0;

  PaymentListViewModel({required this.item, required this.receipt});

  /// Carrega os pagamentos e recalcula o total pago a partir da própria lista,
  /// garantindo que a label de total reflita imediatamente o estado atual.
  Future<void> inicialData() async {
    foundPayment = await db.getListPayment(receipt, item);
    _calcTotal();
    notifyListeners();
  }

  void _calcTotal() {
    totalPaid = 0;
    for (final payment in foundPayment) {
      totalPaid += payment.PRECO ?? 0;
    }
  }

  Future<void> refresh() => inicialData();

  Future<void> deletePayment(BuildContext context, int index) async {
    loadingEvent.alertLoading(context);
    try {
      await db.deletePaymentCustomer(foundPayment[index].id!);
      loadingEvent.closeLoading(context);
      await displayAlert.notificationNotCloseScreen(
          context, "Feito!", "Pagamento removido com sucesso!");
    } catch (e) {
      loadingEvent.closeLoading(context);
      await displayAlert.notificationError(
          context, "Erro!", "Problemas para remover o pagamento");
    }
    await inicialData();
  }

  Future<void> editPayment(BuildContext context, int index) async {
    Orcamento.IDRECIBO = receipt.ID;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PaymentCreatorView(item: foundPayment[index])),
    );
    await inicialData();
  }

  Future<void> addPayment(BuildContext context) async {
    final PaymentCustomer novo = PaymentCustomer()
      ..METODO = ''
      ..id = ''
      ..DESCRICAO = 'null'
      ..PRECO = 0;
    Orcamento.IDRECIBO = receipt.ID;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentCreatorView(item: novo)),
    );
    await inicialData();
  }
}
