import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/payment/domain/repository/payment_repository.dart';
import 'package:oflite/shared/common/widgets/modals/option_bottom_modal_widget.dart';
import 'package:oflite/shared/models/payment_customer.dart';

enum Gender {
  descricaoText,
  precoText,
  typeText,
}

class PaymentCreatorViewModel extends ChangeNotifier {
  final PaymentRepository _paymentRepository;
  final ConvertCoinRepository _moneyConvert;
  final LoadingEventRepository _loadingEvent;
  final DisplayAlertRepository _displayAlert;

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

  PaymentCreatorViewModel({
    PaymentRepository? paymentRepository,
    ConvertCoinRepository? convertCoinRepository,
    LoadingEventRepository? loadingEventRepository,
    DisplayAlertRepository? displayAlertRepository,
  })  : _paymentRepository = paymentRepository ?? getIt<PaymentRepository>(),
        _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>(),
        _loadingEvent = loadingEventRepository ?? getIt<LoadingEventRepository>(),
        _displayAlert = displayAlertRepository ?? getIt<DisplayAlertRepository>();

  void init(PaymentCustomer item) {
    try {
      if (item.DESCRICAO.toString() != 'null') {
        nameButton = 'ATUALIZAR';
        titlePage = 'Editar pagamento';
        typeText.text = item.METODO.toString();
        controller.text = _moneyConvert.convertFromDouble(item.PRECO!);
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
    double cleanAmount = _moneyConvert.convertFromString(controller.text);
    _loadingEvent.alertLoading(context);
    if (nameButton == 'SALVAR') {
      ITENS.METODO = typeText.text;
      ITENS.DESCRICAO = descricaoText.text;
      ITENS.PRECO = cleanAmount;
      await _paymentRepository.savePayment(ITENS);
      _loadingEvent.closeLoading(context);
      await _displayAlert.notification(
          context, "Feito!", "Pagamento criado com sucesso!");
    } else if (nameButton == 'ATUALIZAR') {
      ITENS.METODO = typeText.text;
      ITENS.DESCRICAO = descricaoText.text;
      ITENS.PRECO = cleanAmount;
      ITENS.id = item.id;
      await _paymentRepository.updatePayment(ITENS);
      _loadingEvent.closeLoading(context);
      await _displayAlert.notification(
          context, "Feito!", "Pagamento atualizado com sucesso!");
    }
  }
}
