import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/usecases/data/usecase/pdf_generate_usecase.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/shared/models/observation_pdf.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PdfBudgetViewModel extends ChangeNotifier {
  final PdfRepository _pdfRepository = getIt<PdfRepository>();
  final DisplayAlert displayAlert = DisplayAlert();
  final ConvertCoin moneyConvert = ConvertCoin();
  final PdfGenerateUseCase pdf = PdfGenerateUseCase();
  String? fileBytes;
  bool _loading = true;
  bool get loading => _loading;
  bool _disposed = false;

  PdfBudgetViewModel();

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

        final generated = await pdf.patternPDF(
          countService: countService,
          countProduct: countProduct,
          totalPriceBudget: moneyConvert.convertFromDouble(totalBudget),
          totalPriceProducts: moneyConvert.convertFromDouble(totalProducts),
          totalPriceServices: moneyConvert.convertFromDouble(totalServices),
          items: budgetItems,
          customer: customer,
          owner: owner,
          observations: comments,
        );
        fileBytes = generated;
      } else {
        if (context.mounted) {
          await displayAlert.notificationWarning(
            context,
            'Ops!',
            "Para visualizar o PDF do orçamento é necessário incluir apenas um produto ou serviço na aba 'Itens'",
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        await displayAlert.notificationWarning(
          context,
          'Erro',
          'Não foi possível gerar o PDF: ${e.toString()}',
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
