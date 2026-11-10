import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/domain/repository/budget_payment_repository.dart';
import 'package:oflite/modules/receipt/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/common/widgets/modals/option_bottom_modal_widget.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

enum Gender { descricaoText, precoText, typeText }

class ReceiptPaymentCreatorViewModel extends ChangeNotifier {
  final BudgetPaymentRepository _paymentRepository;
  final ConvertCoinRepository _moneyConvert;

  late final Command0<void> saveCommand;

  Gender? selected;
  String? nameButton;
  String? titlePage;
  bool fieldVisible = false;
  PaymentCustomer _item = PaymentCustomer();

  final TextEditingController typeText = TextEditingController();
  final TextEditingController descricaoText = TextEditingController();
  final MoneyMaskedTextController controller = MoneyMaskedTextController(
    leftSymbol: 'R\$ ',
  );

  ReceiptPaymentCreatorViewModel({
    required PaymentCustomer item,
    BudgetPaymentRepository? paymentRepository,
    ConvertCoinRepository? convertCoinRepository,
  }) : _paymentRepository =
           paymentRepository ?? getIt<BudgetPaymentRepository>(),
       _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>() {
    _initFromItem(item);
    saveCommand = Command0(_executeSave);
  }

  void _initFromItem(PaymentCustomer item) {
    _item = item;
    final hasDescricao =
        item.description != null &&
        item.description.toString() != 'null' &&
        item.description.toString().isNotEmpty;

    if (hasDescricao) {
      nameButton = PaymentStrings.updateButton;
      titlePage = PaymentStrings.editPaymentTitle;
      typeText.text = item.method.toString();
      controller.text = _moneyConvert.convertFromDouble(item.price ?? 0);
      descricaoText.text = item.description.toString();
    } else {
      nameButton = PaymentStrings.saveButton;
      titlePage = PaymentStrings.createPaymentTitle;
      typeText.text = PaymentStrings.defaultPaymentType;
      controller.text = '';
      descricaoText.text = '';
    }
    fieldVisible = true;
    notifyListeners();
  }

  void selectField(Gender field) {
    selected = field;
    notifyListeners();
  }

  Future<void> selectType(BuildContext context) async {
    List<String> values = PaymentStrings.paymentTypeOptions;
    final value = await showOptionBottomModal(
      context,
      title: PaymentStrings.selectPaymentTypeTitle,
      values: values,
    );
    if (value != null) {
      typeText.text = value;
      notifyListeners();
    }
  }

  Future<Result<void>> _executeSave() async {
    try {
      final cleanAmount = _moneyConvert.convertFromString(controller.text);

      final currentItem =
          PaymentCustomer()
            ..method = typeText.text
            ..description = descricaoText.text
            ..price = cleanAmount;

      if (nameButton == PaymentStrings.saveButton) {
        await _paymentRepository.savePayment(currentItem);
      } else {
        currentItem.id = _item.id;
        await _paymentRepository.updatePayment(currentItem);
      }

      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  void dispose() {
    typeText.dispose();
    descricaoText.dispose();
    controller.dispose();
    super.dispose();
  }
}
