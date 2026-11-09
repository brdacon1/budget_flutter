import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_repository.dart';
import 'package:oflite/modules/receipt/receipt_tab/presenter/receipt_tab_view.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Gerenciamento de estado da tela de **lista de recibos**.
class ReceiptListViewModel extends ChangeNotifier {
  final ReceiptRepository _receiptRepository = getIt<ReceiptRepository>();
  final ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();
  late final Command1<void, int> deleteReceiptCommand = Command1(
    _deleteReceipt,
  );

  final CustomerInfo item;
  List<Receipt> foundPayment = <Receipt>[];

  ReceiptListViewModel({required this.item});

  Future<void> inicialData({bool forceRefresh = false}) async {
    _receiptRepository.budgetId = item.id;
    final result = await _receiptRepository.fetchReceipts(
      forceRefresh: forceRefresh,
    );
    if (result is Ok<List<Receipt>>) {
      foundPayment = result.value;
    }
    notifyListeners();
  }

  Future<void> refresh() => inicialData(forceRefresh: true);

  Future<Result<void>> _deleteReceipt(int index) async {
    try {
      await _receiptRepository.deleteReceipt(foundPayment[index]);

      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  Future<void> addReceipt(BuildContext context) async {
    final Receipt itens = Receipt(
      data: '',
      id: '',
      descricao: 'null',
      valorTotal: 0,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptTabView(item: item, receipt: itens),
      ),
    );
    await inicialData();
  }
}
