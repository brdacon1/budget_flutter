import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/shared/common/enums/receipt_field_enum.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Gerenciamento de estado da tela de criação/edição de recibo.
class ReceiptCreatorViewModel extends ChangeNotifier {
  final ReceiptRepository _receiptRepository = getIt<ReceiptRepository>();
  final DisplayAlertRepository displayAlert = getIt<DisplayAlertRepository>();
  final LoadingEventRepository loadingEvent = getIt<LoadingEventRepository>();

  final Receipt receipt;
  final ValueChanged<Receipt>? onReceiptCreated;

  final TextEditingController descricaoText = TextEditingController();
  final TextEditingController idText = TextEditingController();
  final TextEditingController dataText = TextEditingController();

  ReceiptFieldType? selectedField;
  late bool fieldVisible;
  late String nameButton;
  late String titlePage;

  ReceiptCreatorViewModel({
    required this.receipt,
    this.onReceiptCreated,
  }) {
    _initFromReceipt();
  }

  void _initFromReceipt() {
    if (receipt.descricao.toString() != 'null') {
      nameButton = ReceiptPtString.updateButton;
      titlePage = ReceiptPtString.editTitle;
      descricaoText.text = receipt.descricao!;
      idText.text = receipt.id!;
      dataText.text = receipt.data!;
      fieldVisible = true;
    } else {
      nameButton = ReceiptPtString.saveButton;
      titlePage = ReceiptPtString.createTitle;
      descricaoText.text = '';
      idText.text = '';
      dataText.text = '';
      fieldVisible = false;
    }
  }

  String get formSubtitle =>
      fieldVisible && nameButton == ReceiptPtString.updateButton
          ? ReceiptPtString.formCardSubtitleEdit
          : ReceiptPtString.formCardSubtitleCreate;

  void selectField(ReceiptFieldType field) {
    selectedField = field;
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    loadingEvent.alertLoading(context);

    if (nameButton == ReceiptPtString.saveButton) {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);

      final Receipt novo = Receipt(
        descricao: descricaoText.text,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        data: formatted,
        valorTotal: 0,
      );

      final result = await _receiptRepository.saveReceipt(novo);
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);

      if (result is Ok<void>) {
        await displayAlert.notificationNotCloseScreen(
            context, ReceiptPtString.doneTitle, ReceiptPtString.createSuccess);
        onReceiptCreated?.call(novo);
        dataText.text = novo.data!;
        descricaoText.text = novo.descricao!;
        idText.text = novo.id!;
        fieldVisible = true;
        notifyListeners();
      } else if (result is Error<void>) {
        await displayAlert.notificationError(
            context, ReceiptPtString.errorTitle, 'Erro ao salvar recibo');
      }
      return;
    }

    if (nameButton == ReceiptPtString.updateButton && fieldVisible) {
      final Receipt atualizado = receipt.copyWith(descricao: descricaoText.text);
      final result = await _receiptRepository.saveReceipt(atualizado);
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);

      if (result is Ok<void>) {
        await displayAlert.notificationNotCloseScreen(
            context, ReceiptPtString.doneTitle, ReceiptPtString.updateSuccess);
        notifyListeners();
      } else if (result is Error<void>) {
        await displayAlert.notificationError(
            context, ReceiptPtString.errorTitle, 'Erro ao atualizar recibo');
      }
    }
  }

  @override
  void dispose() {
    descricaoText.dispose();
    idText.dispose();
    dataText.dispose();
    super.dispose();
  }
}
