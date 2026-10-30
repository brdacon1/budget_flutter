import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_usecase.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/modules/pdf/presenter/strings/pdf_pt_string.dart';

class PdfBudgetViewModel extends ChangeNotifier {
  final PdfRepository _pdfRepository;
  final DisplayAlertRepository _displayAlert;
  final ConvertCoinRepository _moneyConvert;
  final PdfGenerateUseCase _pdfGenerateUseCase;

  String? fileBytes;
  bool _loading = true;
  bool get loading => _loading;
  bool _disposed = false;

  PdfBudgetViewModel({
    PdfRepository? pdfRepository,
    DisplayAlertRepository? displayAlertRepository,
    ConvertCoinRepository? convertCoinRepository,
    PdfGenerateUseCase? pdfGenerateUseCase,
  })  : _pdfRepository = pdfRepository ?? getIt<PdfRepository>(),
        _displayAlert = displayAlertRepository ?? getIt<DisplayAlertRepository>(),
        _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>(),
        _pdfGenerateUseCase = pdfGenerateUseCase ?? getIt<PdfGenerateUseCase>();

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

      final itemsResult = await _pdfRepository
          .fetchBudgetItems(budget.IDORCAMENTO ?? '', forceRefresh: true);
      if (itemsResult is Ok<List<ItemsBudget>>) {
        budgetItems = itemsResult.value;
      }

      final customerResult = await _pdfRepository
          .fetchBudgetById(budget.IDORCAMENTO ?? '', forceRefresh: true);
      if (customerResult is Ok<CustomerInfo>) {
        customer = customerResult.value;
      }

      final ownerResult =
          await _pdfRepository.fetchInformationEnterprise(forceRefresh: true);
      if (ownerResult is Ok<OwnerPdf>) {
        owner = ownerResult.value;
      }

      final commentResult = await _pdfRepository
          .fetchBudgetComments(budget.IDORCAMENTO ?? '', forceRefresh: true);
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

        final generated = await _pdfGenerateUseCase.patternPDF(
          countService: countService,
          countProduct: countProduct,
          totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
          totalPriceProducts: _moneyConvert.convertFromDouble(totalProducts),
          totalPriceServices: _moneyConvert.convertFromDouble(totalServices),
          items: budgetItems,
          customer: customer,
          owner: owner,
          observations: comments,
        );
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
