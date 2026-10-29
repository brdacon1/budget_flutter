import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/usecases/data/usecase/pdf_generate_receipt_usecase.dart';
import 'package:oflite/modules/payment/domain/repository/payment_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/models/payment_customer.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PdfReceiptViewModel extends ChangeNotifier {
  final PdfRepository _pdfRepository = getIt<PdfRepository>();
  final PaymentRepository _paymentRepository = getIt<PaymentRepository>();
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

  Future<void> initialData(BuildContext context) async {
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

      final paymentResult =
          await _paymentRepository.fetchPayments(receipt, forceRefresh: true);
      List<PaymentCustomer> paymentList = [];
      if (paymentResult is Ok<List<PaymentCustomer>>) {
        paymentList = paymentResult.value;
      }

      final ownerResult =
          await _pdfRepository.fetchInformationEnterprise(forceRefresh: true);
      OwnerPdf? owner;
      if (ownerResult is Ok<OwnerPdf>) {
        owner = ownerResult.value;
      }

      if (owner == null) {
        throw Exception('Owner info not found');
      }

      double totalBudget = 0;
      for (final p in paymentList) {
        totalBudget += p.PRECO ?? 0;
      }

      final path = await pdf.patternPDF(
        paymentList: paymentList,
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

  Future<void> refresh(BuildContext context) => initialData(context);
}
