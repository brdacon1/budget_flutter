import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/modules/receipt/receipt_tab/presenter/receipt_tab_view.dart';
import 'package:oflite/shared/common/strings/receipt_strings.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Gerenciamento de estado da tela de **lista de recibos**.
class ReceiptListViewModel extends ChangeNotifier {
  final ReceiptRepository _receiptRepository = getIt<ReceiptRepository>();
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  final CustomerInfo item;
  List<Receipt> foundPayment = <Receipt>[];

  ReceiptListViewModel({required this.item});

  Future<void> inicialData() async {
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
            context, ReceiptStrings.doneTitle, ReceiptStrings.deleteSuccess);
        await inicialData();
      } else if (result is Error<void>) {
        throw result.error;
      }
    } catch (e) {
      loadingEvent.closeLoading(context);
      await displayAlert.notificationError(
          context, ReceiptStrings.errorTitle, ReceiptStrings.deleteError);
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
