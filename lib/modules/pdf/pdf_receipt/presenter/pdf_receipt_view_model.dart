import 'package:flutter/material.dart';
import 'package:oflite/modules/core/services/data/service/http_request.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/usecases/data/usecase/pdf_generate_receipt_usecase.dart';

class PdfReceiptViewModel extends ChangeNotifier {
  final HttpRequest db = HttpRequest();
  final DisplayAlert displayAlert = DisplayAlert();
  final ConvertCoin moneyConvert = ConvertCoin();
  final PdfGenerateReceiptUseCase pdf = PdfGenerateReceiptUseCase();

  final Receipt receipt;
  final CustomerInfo item;

  String? fileBytes;
  bool loading = false;
  bool hasError = false;
  bool empty = false;

  PdfReceiptViewModel({required this.receipt, required this.item});

  Future<void> inicialData(BuildContext context) async {
    loading = true;
    hasError = false;
    empty = false;
    notifyListeners();

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        loading = false;
        notifyListeners();
        return;
      }

      final recived = await db.getListRecived();
      final payment = await db.getListPayment(receipt, item);
      final owner = await db.getInformationEnterprise();

      if (recived.isEmpty) {
        fileBytes = null;
        empty = true;
        loading = false;
        notifyListeners();
        await displayAlert.notificationError(
          context,
          'Erro!',
          "Para visualizar o PDF do orçamento é necessário incluir apenas um produto ou serviço na aba 'Itens'",
        );
        return;
      }

      double totalBudget = 0;
      for (final p in payment) {
        totalBudget += p.PRECO!;
      }

      final path = await pdf.patternPDF(
        paymentList: payment,
        recived: receipt,
        totalPriceBudget: moneyConvert.convertFromDouble(totalBudget),
        customer: item,
        owner: owner,
      );

      fileBytes = path;
      loading = false;
      notifyListeners();
    } catch (_) {
      hasError = true;
      loading = false;
      fileBytes = null;
      notifyListeners();
    }
  }

  Future<void> refresh(BuildContext context) => inicialData(context);
}
