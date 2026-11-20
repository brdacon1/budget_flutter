import 'package:oflite/modules/receipt/domain/entity/payment_method.dart';
import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_payment_repository.dart';
import 'package:oflite/modules/receipt/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/common/widgets/modals/option_bottom_modal_widget.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

enum Gender { descricaoText, precoText, typeText }

class ReceiptPaymentCreatorViewModel extends ChangeNotifier {
  final ReceiptPaymentRepository _paymentRepository;
  final ConvertCoinRepository _moneyConvert;

  late final Command0<void> saveCommand;

  Gender? selected;
  String? nameButton;
  String? titlePage;
  bool fieldVisible = false;
  PaymentCustomer _item = PaymentCustomer();

  String? priceError;
  String? descricaoError;

  /// Editar = pagamento já persistido (tem id). Não depende da descrição.
  bool get isEditing => _item.id != null && _item.id!.isNotEmpty;

  final TextEditingController typeText = TextEditingController();
  final TextEditingController descricaoText = TextEditingController();
  final MoneyMaskedTextController controller = MoneyMaskedTextController(
    leftSymbol: 'R\$ ',
  );

  ReceiptPaymentCreatorViewModel({
    required PaymentCustomer item,
    ReceiptPaymentRepository? paymentRepository,
    ConvertCoinRepository? convertCoinRepository,
  }) : _paymentRepository =
           paymentRepository ?? getIt<ReceiptPaymentRepository>(),
       _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>() {
    _initFromItem(item);
    saveCommand = Command0(_executeSave);
    controller.addListener(_clearPriceError);
    descricaoText.addListener(_clearDescricaoError);
  }

  void _clearPriceError() {
    if (priceError != null &&
        _moneyConvert.convertFromString(controller.text) > 0) {
      priceError = null;
      notifyListeners();
    }
  }

  void _clearDescricaoError() {
    if (descricaoError != null && descricaoText.text.trim().isNotEmpty) {
      descricaoError = null;
      notifyListeners();
    }
  }

  /// Valor pago (> 0) e descrição são obrigatórios.
  bool _validate() {
    final price =
        controller.text.trim().isEmpty
            ? 0.0
            : _moneyConvert.convertFromString(controller.text);
    priceError = price > 0 ? null : PaymentStrings.priceRequired;
    descricaoError =
        descricaoText.text.trim().isNotEmpty
            ? null
            : PaymentStrings.descriptionRequired;
    notifyListeners();
    return priceError == null && descricaoError == null;
  }

  /// Valida e, se ok, dispara o salvamento.
  void submit() {
    if (saveCommand.running || !_validate()) return;
    saveCommand.execute();
  }

  void _initFromItem(PaymentCustomer item) {
    _item = item;

    if (isEditing) {
      nameButton = PaymentStrings.updateButton;
      titlePage = PaymentStrings.editPaymentTitle;
      typeText.text = PaymentMethod.labelOf(item.method);
      controller.text = _moneyConvert.convertFromDouble(item.price ?? 0);
      final desc = item.description;
      descricaoText.text = (desc == null || desc == 'null') ? '' : desc;
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
            ..method =
                PaymentMethod.fromValue(typeText.text)?.value ?? typeText.text
            ..description = descricaoText.text.trim()
            ..price = cleanAmount;

      if (isEditing) {
        currentItem.id = _item.id;
        return await _paymentRepository.updatePayment(currentItem);
      }
      return await _paymentRepository.savePayment(currentItem);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  void dispose() {
    controller.removeListener(_clearPriceError);
    descricaoText.removeListener(_clearDescricaoError);
    typeText.dispose();
    descricaoText.dispose();
    controller.dispose();
    super.dispose();
  }
}
