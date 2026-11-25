import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget/pdf_generate_budget_executive_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget/pdf_generate_budget_professional_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget/pdf_generate_budget_simple_usecase.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';

/// Geração/visualização do PDF no fluxo Web.
///
/// Reutiliza integralmente o `PdfGenerateUseCase` (a mesma regra de negócio
/// do PDF do app mobile) — apenas pede os **bytes**. No Web o logo é baixado
/// sem token (URL pública do Storage), já que não há login do dono.
class BudgetWebPdfViewModel extends ChangeNotifier {
  BudgetWebPdfViewModel({
    required this.items,
    required this.customer,
    required this.owner,
    required this.observations,
    PdfGenerateBudgetSimpleUsecase? pdfGenerateUseCase,
    PdfGenerateBudgetExecutiveUsecase? pdfGenerateExecutiveUseCase,
    PdfGenerateBudgetProfessionalUsecase? pdfGenerateProfessionalUseCase,
    ConvertCoinRepository? convertCoinRepository,
      }) : _pdfGenerateUseCase =
           pdfGenerateUseCase ?? getIt<PdfGenerateBudgetSimpleUsecase>(),
       _pdfExecutive =
           pdfGenerateExecutiveUseCase ??
           getIt<PdfGenerateBudgetExecutiveUsecase>(),
       _pdfProfessional =
           pdfGenerateProfessionalUseCase ??
           getIt<PdfGenerateBudgetProfessionalUsecase>(),
       _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>();

  final List<ItemsBudget> items;
  final CustomerInfo customer;
  final OwnerPdf owner;
  final List<ObservationPdf> observations;

  final PdfGenerateBudgetSimpleUsecase _pdfGenerateUseCase;
  final PdfGenerateBudgetExecutiveUsecase _pdfExecutive;
  final PdfGenerateBudgetProfessionalUsecase _pdfProfessional;
  final ConvertCoinRepository _moneyConvert;
  
  Uint8List? _bytes;

  Uint8List? get bytes => _bytes;

  bool _loading = true;

  bool get loading => _loading;

  bool _disposed = false;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> initialData(BuildContext context) async {
    _loading = true;
    _safeNotify();
    try {
      if (items.isEmpty) {
        _bytes = null;
        if (context.mounted) {
          AlertSnackBar.warning(
            context,
            BudgetWebStrings.pdfTitle,
            BudgetWebStrings.pdfEmpty,
          );
        }
      } else {
        double totalProducts = 0;
        double totalServices = 0;
        double totalBudget = 0;
        int countProduct = 0;
        int countService = 0;
        for (final i in items) {
          final total = i.total ?? 0;
          if (ItemCategory.fromValue(i.category) == ItemCategory.products) {
            totalProducts += total;
            countProduct++;
          } else if (ItemCategory.fromValue(i.category) == ItemCategory.services) {
            totalServices += total;
            countService++;
          }
          totalBudget += total;
        }
        // O `PdfGenerateUseCase` chama `items.clear()` / `observations.clear()`
        // ao final da geração (comportamento legado do app mobile, onde a
        // lista passada é local e descartável). No Web, porém, `items` e
        // `observations` são a **mesma referência** da lista viva da aba
        // "Meus dados" (vinda do `BudgetWebBudgetViewModel`) — se deixarmos o
        // use case limpá-las, a aba de dados fica sem itens após gerar o PDF
        // e a pré-visualização só funciona na 1ª vez. Passamos **cópias**, sem
        // tocar na regra do use case (mobile permanece idêntico).
        final layoutType = owner.pdfLayoutType ?? 'standard';
        final Uint8List bytes;
        switch (layoutType) {
          case 'executive':
            bytes = await _pdfExecutive.executivePDFBytes(
              countService: countService,
              countProduct: countProduct,
              totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
              totalPriceProducts: _moneyConvert.convertFromDouble(
                totalProducts,
              ),
              totalPriceServices: _moneyConvert.convertFromDouble(
                totalServices,
              ),
              items: List<ItemsBudget>.from(items),
              customer: customer,
              owner: owner,
              observations: List<ObservationPdf>.from(observations),
            );
          case 'professional':
            bytes = await _pdfProfessional.professionalPDFBytes(
              countService: countService,
              countProduct: countProduct,
              totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
              totalPriceProducts: _moneyConvert.convertFromDouble(
                totalProducts,
              ),
              totalPriceServices: _moneyConvert.convertFromDouble(
                totalServices,
              ),
              items: List<ItemsBudget>.from(items),
              customer: customer,
              owner: owner,
              observations: List<ObservationPdf>.from(observations),
            );
          default:
            bytes = await _pdfGenerateUseCase.patternPDFBytes(
              countService: countService,
              countProduct: countProduct,
              totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
              totalPriceProducts: _moneyConvert.convertFromDouble(
                totalProducts,
              ),
              totalPriceServices: _moneyConvert.convertFromDouble(
                totalServices,
              ),
              items: List<ItemsBudget>.from(items),
              customer: customer,
              owner: owner,
              observations: List<ObservationPdf>.from(observations),
            );
        }
        _bytes = bytes;
      }
    } catch (e) {
      if (context.mounted) {
        AlertSnackBar.warning(
          context,
          BudgetWebStrings.pdfTitle,
          '${BudgetWebStrings.pdfError} ${e.toString()}',
        );
      }
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
