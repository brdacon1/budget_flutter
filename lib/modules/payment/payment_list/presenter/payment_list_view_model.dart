import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';
import 'package:oflite/modules/payment/domain/repository/payment_repository.dart';
import 'package:oflite/modules/payment/payment_creator/presenter/payment_creator_view.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as Orcamento;
import 'package:oflite/shared/models/payment_customer.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PaymentListViewModel extends ChangeNotifier {
  final PaymentRepository _paymentRepository = getIt<PaymentRepository>();
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  final CustomerInfo item;
  final Receipt receipt;

  List<PaymentCustomer> foundPayment = <PaymentCustomer>[];
  double totalPaid = 0;

  PaymentListViewModel({required this.item, required this.receipt});

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
    loadingEvent.alertLoading(context);
    try {
      final result =
          await _paymentRepository.deletePayment(foundPayment[index].id!);
      loadingEvent.closeLoading(context);
      if (result is Ok<void>) {
        await displayAlert.notificationNotCloseScreen(
            context, "Feito!", "Pagamento removido com sucesso!");
      }
    } catch (e) {
      loadingEvent.closeLoading(context);
      await displayAlert.notificationError(
          context, "Erro!", "Problemas para remover o pagamento");
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
      await displayAlert.notificationWarning(
        context,
        'Recibo não salvo',
        'Salve o recibo na aba "Recibo" antes de adicionar pagamentos.',
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
