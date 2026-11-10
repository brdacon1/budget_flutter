import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/payment_customer.dart';
import 'package:oflite/modules/budget/domain/repository/budget_payment_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/entity/pdf_layout_type.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_receipt/pdf_generate_receipt_executive_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_receipt/pdf_generate_receipt_professional_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_receipt/pdf_generate_receipt_simple_usecase.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfReceiptViewModel extends ChangeNotifier {
  final PdfRepository _pdfRepository;
  final BudgetPaymentRepository _paymentRepository;
  final ConvertCoinRepository _moneyConvert;
  final PdfGenerateReceiptUseCase _pdfGenerateReceiptUseCase;
  final PdfGenerateReceiptExecutiveUsecase _pdfGenerateReceiptExecutive;
  final PdfGenerateReceiptProfessionalUsecase _pdfGenerateReceiptProfessional;

  final Receipt receipt;
  final CustomerInfo item;

  String? fileBytes;
  bool loading = false;
  bool hasError = false;
  bool empty = false;

  PdfLayoutType _layoutType = PdfLayoutType.standard;

  void setLayoutType(PdfLayoutType type) {
    _layoutType = type;
  }

  PdfReceiptViewModel({
    required this.receipt,
    required this.item,
    PdfRepository? pdfRepository,
    BudgetPaymentRepository? paymentRepository,
    ConvertCoinRepository? convertCoinRepository,
    PdfGenerateReceiptUseCase? pdfGenerateReceiptUseCase,
    PdfGenerateReceiptExecutiveUsecase? pdfGenerateReceiptExecutive,
    PdfGenerateReceiptProfessionalUsecase? pdfGenerateReceiptProfessional,
  }) : _pdfRepository = pdfRepository ?? getIt<PdfRepository>(),
       _paymentRepository =
           paymentRepository ?? getIt<BudgetPaymentRepository>(),
       _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>(),
       _pdfGenerateReceiptUseCase =
           pdfGenerateReceiptUseCase ?? getIt<PdfGenerateReceiptUseCase>(),
       _pdfGenerateReceiptExecutive =
           pdfGenerateReceiptExecutive ??
           getIt<PdfGenerateReceiptExecutiveUsecase>(),
       _pdfGenerateReceiptProfessional =
           pdfGenerateReceiptProfessional ??
           getIt<PdfGenerateReceiptProfessionalUsecase>();

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

      _paymentRepository.budgetId = item.id;
      _paymentRepository.receiptId = receipt.id;

      final paymentResult = await _paymentRepository.fetchPayments(
        receipt,
        forceRefresh: true,
      );
      List<PaymentCustomer> paymentList = [];
      if (paymentResult is Ok<List<PaymentCustomer>>) {
        paymentList = paymentResult.value;
      }

      final ownerResult = await _pdfRepository.fetchInformationEnterprise(
        forceRefresh: true,
      );
      OwnerPdf? owner;
      if (ownerResult is Ok<OwnerPdf>) {
        owner = ownerResult.value;
      }

      if (owner == null) {
        throw Exception('Owner info not found');
      }

      double totalBudget = 0;
      for (final p in paymentList) {
        totalBudget += p.price ?? 0;
      }

      final ownerLayout = owner.pdfLayoutType ?? 'standard';
      final effectiveLayout =
          _layoutType != PdfLayoutType.standard
              ? _layoutType
              : PdfLayoutType.values.firstWhere(
                (e) => e.name == ownerLayout,
                orElse: () => PdfLayoutType.standard,
              );

      final String path;
      switch (effectiveLayout) {
        case PdfLayoutType.executive:
          path = await _pdfGenerateReceiptExecutive.executivePDF(
            paymentList: paymentList,
            recived: receipt,
            totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
            customer: item,
            owner: owner,
          );
        case PdfLayoutType.professional:
          path = await _pdfGenerateReceiptProfessional.professionalPDF(
            paymentList: paymentList,
            recived: receipt,
            totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
            customer: item,
            owner: owner,
          );
        default:
          path = await _pdfGenerateReceiptUseCase.patternPDF(
            paymentList: paymentList,
            recived: receipt,
            totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
            customer: item,
            owner: owner,
          );
      }

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
