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

enum Gender {
  comentText,
}

class PaymentListViewModel extends ChangeNotifier {
  var displayAlert = DisplayAlert();
  var db = HttpRequest();
  var loadingEvent = LoadingEvent();
  var foundPayment = <PaymentCustomer>[];
  var deleteItems = <PaymentCustomer>[];
  ConvertCoin moneyConvert = ConvertCoin();
  Gender? selected;
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;

  CustomerInfo? item;
  Receipt? recibos;

  Future<void> inicialData() async {
    foundPayment = await db.getListPayment(recibos!, item!);
    notifyListeners();
  }

  void init(CustomerInfo item, Receipt recibos) {
    this.item = item;
    this.recibos = recibos;
    inicialData();
  }

  Future<void> refresh() async {
    await inicialData();
  }

  Future<void> deletePayment(BuildContext context, int index) async {
    loadingEvent.alertLoading(context);
    try {
      await db.deletePaymentCustomer(foundPayment[index].id!).then((value) async => {
            loadingEvent.closeLoading(context),
            await displayAlert.notificationNotCloseScreen(
                context, "Feito!", "Pagamento removido com sucesso!"),
          });
    } catch (e) {
      loadingEvent.closeLoading(context);
      await displayAlert.notificationError(
          context, "Erro!", "Problemas para remover o pagamento");
    }

    await inicialData();
  }

  Future<void> editPayment(BuildContext context, int index) async {
    Orcamento.IDRECIBO = recibos!.ID;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PaymentCreatorView(item: foundPayment[index])),
    ).then((value) async => {
          inicialData(),
        });
  }

  Future<void> addPayment(BuildContext context) async {
    PaymentCustomer ITENS = PaymentCustomer();
    ITENS.METODO = '';
    ITENS.id = '';
    ITENS.DESCRICAO = 'null';
    ITENS.PRECO = 0;
    Orcamento.IDRECIBO = recibos!.ID;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentCreatorView(item: ITENS)),
    ).then((value) async => {
          inicialData(),
        });
  }
}
