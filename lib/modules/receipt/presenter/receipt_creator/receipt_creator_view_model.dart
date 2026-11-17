import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Gerenciamento de estado da tela de criação/edição de recibo.
class ReceiptCreatorViewModel extends ChangeNotifier {
  final ReceiptRepository _receiptRepository = getIt<ReceiptRepository>();
  final DisplayAlertRepository displayAlert = getIt<DisplayAlertRepository>();

  Receipt receipt;
  final CustomerInfo item;
  final ValueChanged<Receipt>? onReceiptCreated;

  final TextEditingController descricaoText = TextEditingController();
  final FocusNode descricaoNode = FocusNode();

  String? descricaoError;
  bool saving = false;
  String _snapshot = '';

  ReceiptCreatorViewModel({
    required this.receipt,
    required this.item,
    this.onReceiptCreated,
  }) {
    descricaoText.text = isEditing ? receipt.descricao! : '';
    _snapshot = descricaoText.text;
    descricaoText.addListener(_onChanged);
  }

  bool get isEditing =>
      receipt.descricao != null && receipt.descricao.toString() != 'null';

  String get titlePage =>
      isEditing ? ReceiptPtString.editTitle : ReceiptPtString.createTitle;

  String get nameButton => isEditing
      ? ReceiptPtString.saveChangesButton
      : ReceiptPtString.continueButton;

  /// No modo criar o botão fica sempre destacado; no editar, só com mudanças.
  bool get isDirty => !isEditing || descricaoText.text != _snapshot;

  void _onChanged() {
    if (descricaoError != null && descricaoText.text.trim().isNotEmpty) {
      descricaoError = null;
    }
    notifyListeners();
  }

  void updateReceipt(Receipt newReceipt) {
    receipt = newReceipt;
    notifyListeners();
  }

  bool _validate() {
    if (descricaoText.text.trim().isEmpty) {
      descricaoError = ReceiptPtString.descriptionRequired;
      descricaoNode.requestFocus();
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> save(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (saving || !_validate()) return;

    _receiptRepository.budgetId = item.id;
    final creating = !isEditing;
    final descricao = descricaoText.text.trim();

    final Receipt target = creating
        ? Receipt(
            descricao: descricao,
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            data: DateFormat('dd/MM/yyyy').format(DateTime.now()),
            valorTotal: 0,
          )
        : receipt.copyWith(descricao: descricao);

    saving = true;
    notifyListeners();
    final result = await _receiptRepository.saveReceipt(target);
    saving = false;
    if (!context.mounted) return;

    if (result is Error<void>) {
      notifyListeners();
      await displayAlert.notificationError(
        context,
        ReceiptPtString.saveErrorTitle,
        ReceiptPtString.saveErrorMessage,
      );
      return;
    }

    // Após criar, a tela passa ao modo editar (evita criar duplicado).
    receipt = target;
    _snapshot = descricao;
    notifyListeners();

    if (creating) {
      onReceiptCreated?.call(target);
      await displayAlert.notificationNotCloseScreen(
        context,
        ReceiptPtString.doneTitle,
        ReceiptPtString.createdNextStep,
      );
    } else {
      await displayAlert.notificationNotCloseScreen(
        context,
        ReceiptPtString.changesSaved,
        ReceiptPtString.changesSavedMessage,
      );
    }
  }

  @override
  void dispose() {
    descricaoText.removeListener(_onChanged);
    descricaoText.dispose();
    descricaoNode.dispose();
    super.dispose();
  }
}
