import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/material.dart';
import 'package:oflite/Services/display_alert.dart';
import 'package:oflite/Services/http_request.dart';
import 'package:oflite/common/widgets/modals/option_bottom_modal_widget.dart';
import 'package:oflite/services/convert_coin.dart';
import '../../../Services/loading_event.dart';
import '../../../models/payment_customer.dart';

enum Gender {
  descricaoText,
  precoText,
  typeText,
}

class PaymentCreatorViewModel extends ChangeNotifier {
  Color enabledtxt = Colors.white;
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  String? titlePage;
  bool fieldVisible = false;
  PaymentCustomer ITENS = PaymentCustomer();

  final TextEditingController typeText = TextEditingController();
  final TextEditingController precoText = TextEditingController();
  final TextEditingController descricaoText = TextEditingController();
  final MoneyMaskedTextController controller =
      MoneyMaskedTextController(leftSymbol: 'R\$ ');

  final ConvertCoin moneyConvert = ConvertCoin();
  final db = HttpRequest();
  final loadingEvent = LoadingEvent();
  final displayAlert = DisplayAlert();

  void init(PaymentCustomer item) {
    try {
      if (item.DESCRICAO.toString() != 'null') {
        nameButton = 'ATUALIZAR';
        titlePage = 'Editar pagamento';
        typeText.text = item.METODO.toString();
        controller.text = moneyConvert.convertFromDouble(item.PRECO!);
        descricaoText.text = item.DESCRICAO.toString();
        fieldVisible = true;
      } else {
        nameButton = 'SALVAR';
        titlePage = 'Criar pagamento';
        typeText.text = 'Dinheiro';
        controller.text = '';
        descricaoText.text = '';
        precoText.text = '1';
        fieldVisible = true;
      }
      notifyListeners();
    } catch (e) {}
  }

  void selectField(Gender field) {
    selected = field;
    notifyListeners();
  }

  Future<void> selectType(BuildContext context) async {
    List<String> values = ['Crédito', 'Débito', 'Dinheiro', 'PIX'];
    final value = await showOptionBottomModal(
      context,
      title: 'Tipo do pagamento',
      values: values,
    );
    if (value != null) {
      typeText.text = value;
      notifyListeners();
    }
  }

  Future<void> save(BuildContext context, PaymentCustomer item) async {
    double cleanAmount = moneyConvert.convertFromString(controller.text);
    loadingEvent.alertLoading(context);
    if (nameButton == 'SALVAR') {
      ITENS.METODO = typeText.text;
      ITENS.DESCRICAO = descricaoText.text;
      ITENS.PRECO = cleanAmount;
      await db.savePaymentCustomer(ITENS).then((value) => {
            loadingEvent.closeLoading(context),
            displayAlert.notification(
                context, "Feito!", "Pagamento criado com sucesso!"),
          });
    } else if (nameButton == 'ATUALIZAR') {
      ITENS.METODO = typeText.text;
      ITENS.DESCRICAO = descricaoText.text;
      ITENS.PRECO = cleanAmount;
      ITENS.id = item.id;
      await db.updatePaymentCustomer(ITENS).then((value) => {
            loadingEvent.closeLoading(context),
            displayAlert.notification(
                context, "Feito!", "Pagamento atualizado com sucesso!"),
          });
    }
  }
}
