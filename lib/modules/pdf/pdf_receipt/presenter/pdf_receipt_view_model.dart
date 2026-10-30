import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_receipt_usecase.dart';
import 'package:oflite/modules/payment/domain/repository/payment_repository.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/models/payment_customer.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PdfReceiptViewModel extends ChangeNotifier {
  final PdfRepository _pdfRepository;
  final PaymentRepository _paymentRepository;
  final ConvertCoinRepository _moneyConvert;
  final PdfGenerateReceiptUseCase _pdfGenerateReceiptUseCase;

  final Receipt receipt;
  final CustomerInfo item;

  String? fileBytes;
  bool loading = false;
  bool hasError = false;
  bool empty = false;

  PdfReceiptViewModel({
    required this.receipt,
    required this.item,
    PdfRepository? pdfRepository,
    PaymentRepository? paymentRepository,
    ConvertCoinRepository? convertCoinRepository,
    PdfGenerateReceiptUseCase? pdfGenerateReceiptUseCase,
  })  : _pdfRepository = pdfRepository ?? getIt<PdfRepository>(),
        _paymentRepository = paymentRepository ?? getIt<PaymentRepository>(),
        _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>(),
        _pdfGenerateReceiptUseCase = pdfGenerateReceiptUseCase ?? getIt<PdfGenerateReceiptUseCase>();

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

      // Garante que o path do Firestore no datasource esteja correto
      budget.IDORCAMENTO = item.id;
      budget.IDRECIBO = receipt.id;

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

      final path = await _pdfGenerateReceiptUseCase.patternPDF(
        paymentList: paymentList,
        recived: receipt,
        totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
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
