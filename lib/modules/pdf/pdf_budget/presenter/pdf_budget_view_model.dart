import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/entity/pdf_layout_type.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget/pdf_generate_budget_executive_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget_professional_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget/pdf_generate_budget_simple_usecase.dart';
import 'package:oflite/modules/pdf/presenter/strings/pdf_pt_string.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PdfBudgetViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  final PdfRepository _pdfRepository;
  final DisplayAlertRepository _displayAlert;
  final ConvertCoinRepository _moneyConvert;
  final PdfGenerateBudgetSimpleUsecase _pdfGenerateBudgetUsecase;
  final PdfGenerateBudgetExecutiveUsecase _pdfGenerateExecutiveUseCase;
  final PdfGenerateBudgetProfessionalUsecase _pdfGenerateProfessionalUseCase;

  String? fileBytes;
  bool _loading = true;

  bool get loading => _loading;
  bool _disposed = false;
  PdfLayoutType _layoutType = PdfLayoutType.standard;

  void setLayoutType(PdfLayoutType type) {
    _layoutType = type;
  }

  PdfBudgetViewModel({
    BudgetRepository? budgetRepository,
    PdfRepository? pdfRepository,
    DisplayAlertRepository? displayAlertRepository,
    ConvertCoinRepository? convertCoinRepository,
    PdfGenerateBudgetSimpleUsecase? pdfGenerateBudgetUsecase,
    PdfGenerateBudgetExecutiveUsecase? pdfGenerateExecutiveUseCase,
    PdfGenerateBudgetProfessionalUsecase? pdfGenerateProfessionalUseCase,
  }) : _budgetRepository = budgetRepository ?? getIt<BudgetRepository>(),
       _pdfRepository = pdfRepository ?? getIt<PdfRepository>(),
       _displayAlert =
           displayAlertRepository ?? getIt<DisplayAlertRepository>(),
       _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>(),
       _pdfGenerateBudgetUsecase =
           pdfGenerateBudgetUsecase ?? getIt<PdfGenerateBudgetSimpleUsecase>(),
       _pdfGenerateExecutiveUseCase =
           pdfGenerateExecutiveUseCase ??
           getIt<PdfGenerateBudgetExecutiveUsecase>(),
       _pdfGenerateProfessionalUseCase =
           pdfGenerateProfessionalUseCase ??
           getIt<PdfGenerateBudgetProfessionalUsecase>();

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> initialData(BuildContext context) async {
    _loading = true;
    _safeNotify();
    try {
      List<ItemsBudget> budgetItems = [];
      CustomerInfo? customer;
      OwnerPdf? owner;
      List<ObservationPdf> comments = [];

      final itemsResult = await _pdfRepository.fetchBudgetItems(
        _budgetRepository.selectBudget.value?.id ?? '',
        forceRefresh: true,
      );
      if (itemsResult is Ok<List<ItemsBudget>>) {
        budgetItems = itemsResult.value;
      }

      final customerResult = await _pdfRepository.fetchBudgetById(
        _budgetRepository.selectBudget.value?.id ?? '',
        forceRefresh: true,
      );
      if (customerResult is Ok<CustomerInfo>) {
        customer = customerResult.value;
      }

      final ownerResult = await _pdfRepository.fetchInformationEnterprise(
        forceRefresh: true,
      );
      if (ownerResult is Ok<OwnerPdf>) {
        owner = ownerResult.value;
      }

      final commentResult = await _pdfRepository.fetchBudgetComments(
        _budgetRepository.selectBudget.value?.id ?? '',
        forceRefresh: true,
      );
      if (commentResult is Ok<List<ObservationPdf>>) {
        comments = commentResult.value;
      }

      if (budgetItems.isNotEmpty && customer != null && owner != null) {
        double totalProducts = 0;
        double totalServices = 0;
        double totalBudget = 0;
        int countProduct = 0;
        int countService = 0;

        for (int index = 0; index < budgetItems.length; index++) {
          final item = budgetItems[index];
          final total = item.TOTAL ?? 0;
          if (item.CATEGORIA == 'Produtos') {
            totalProducts += total;
            countProduct++;
          } else if (item.CATEGORIA == 'Serviços') {
            totalServices += total;
            countService++;
          }
          totalBudget += total;
        }

        final ownerLayout = owner.pdfLayoutType ?? 'standard';
        final effectiveLayout =
            _layoutType != PdfLayoutType.standard
                ? _layoutType
                : PdfLayoutType.values.firstWhere(
                  (e) => e.name == ownerLayout,
                  orElse: () => PdfLayoutType.standard,
                );

        final String generated;
        switch (effectiveLayout) {
          case PdfLayoutType.executive:
            generated = await _pdfGenerateExecutiveUseCase.executivePDF(
              countService: countService,
              countProduct: countProduct,
              totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
              totalPriceProducts: _moneyConvert.convertFromDouble(
                totalProducts,
              ),
              totalPriceServices: _moneyConvert.convertFromDouble(
                totalServices,
              ),
              items: budgetItems,
              customer: customer,
              owner: owner,
              observations: comments,
            );
          case PdfLayoutType.professional:
            generated = await _pdfGenerateProfessionalUseCase.professionalPDF(
              countService: countService,
              countProduct: countProduct,
              totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
              totalPriceProducts: _moneyConvert.convertFromDouble(
                totalProducts,
              ),
              totalPriceServices: _moneyConvert.convertFromDouble(
                totalServices,
              ),
              items: budgetItems,
              customer: customer,
              owner: owner,
              observations: comments,
            );
          default:
            generated = await _pdfGenerateBudgetUsecase.patternPDF(
              countService: countService,
              countProduct: countProduct,
              totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
              totalPriceProducts: _moneyConvert.convertFromDouble(
                totalProducts,
              ),
              totalPriceServices: _moneyConvert.convertFromDouble(
                totalServices,
              ),
              items: budgetItems,
              customer: customer,
              owner: owner,
              observations: comments,
            );
        }
        fileBytes = generated;
      } else {
        if (context.mounted) {
          await _displayAlert.notificationWarning(
            context,
            'Ops!',
            "Para visualizar o PDF do orçamento é necessário incluir apenas um produto ou serviço na aba 'Itens'",
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        await _displayAlert.notificationWarning(
          context,
          PdfStrings.errorTitle,
          '${PdfStrings.notPossibleGeneratePdf}: ${e.toString()}',
        );
      }
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  Future<void> refresh(BuildContext context) => initialData(context);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
