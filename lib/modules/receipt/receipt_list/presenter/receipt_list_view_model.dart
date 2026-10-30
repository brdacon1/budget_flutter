import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/modules/receipt/receipt_tab/presenter/receipt_tab_view.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Gerenciamento de estado da tela de **lista de recibos**.
class ReceiptListViewModel extends ChangeNotifier {
  final ReceiptRepository _receiptRepository = getIt<ReceiptRepository>();
  final DisplayAlertRepository displayAlert = getIt<DisplayAlertRepository>();
  final LoadingEventRepository loadingEvent = getIt<LoadingEventRepository>();
  final ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();

  final CustomerInfo item;
  List<Receipt> foundPayment = <Receipt>[];

  ReceiptListViewModel({required this.item});

  Future<void> inicialData() async {
    // Path do Firestore depende da global budget.IDORCAMENTO.
    // Garante que está setada antes de buscar recibos.
    budget.IDORCAMENTO = item.id;
    final result = await _receiptRepository.fetchReceipts();
    if (result is Ok<List<Receipt>>) {
      foundPayment = result.value;
    }
    notifyListeners();
  }

  Future<void> refresh() => inicialData();

  Future<void> deleteReceipt(BuildContext context, int index) async {
    try {
      loadingEvent.alertLoading(context);
      final result = await _receiptRepository.deleteReceipt(foundPayment[index]);
      loadingEvent.closeLoading(context);
      if (result is Ok<void>) {
        await displayAlert.notificationNotCloseScreen(
            context, ReceiptPtString.doneTitle, ReceiptPtString.deleteSuccess);
        await inicialData();
      } else if (result is Error<void>) {
        throw result.error;
      }
    } catch (e) {
      loadingEvent.closeLoading(context);
      await displayAlert.notificationError(
          context, ReceiptPtString.errorTitle, ReceiptPtString.deleteError);
    }
  }

  Future<void> openReceipt(BuildContext context, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptTabView(
          item: item,
          receipt: foundPayment[index],
        ),
      ),
    );
    await inicialData();
  }

  Future<void> addReceipt(BuildContext context) async {
    final Receipt itens = Receipt(
      data: '',
      id: '',
      descricao: 'null',
      valorTotal: 0,
    );
    budget.IDRECIBO = DateTime.now().millisecondsSinceEpoch.toString();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptTabView(item: item, receipt: itens),
      ),
    );
    await inicialData();
  }
}
