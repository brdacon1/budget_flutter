import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_executive_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_professional_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_generate_budget_usecase.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';

/// Geração/visualização do PDF no fluxo Web.
///
/// Reutiliza integralmente o `PdfGenerateUseCase` (a mesma regra de negócio
/// do PDF do app mobile) — apenas pede os **bytes** (`patternPDFBytes`) e
/// passa o token provisório do Firebase para baixar o logo, já que no Web
/// não há login do dono.
class BudgetWebPdfViewModel extends ChangeNotifier {
  BudgetWebPdfViewModel({
    required this.items,
    required this.customer,
    required this.owner,
    required this.observations,
    required this.token,
    PdfGenerateBudgetUsecase? pdfGenerateUseCase,
    PdfGenerateExecutiveUseCase? pdfGenerateExecutiveUseCase,
    PdfGenerateProfessionalUseCase? pdfGenerateProfessionalUseCase,
    ConvertCoinRepository? convertCoinRepository,
    DisplayAlertRepository? displayAlertRepository,
  })  : _pdfGenerateUseCase = pdfGenerateUseCase ?? getIt<PdfGenerateBudgetUsecase>(),
        _pdfExecutive = pdfGenerateExecutiveUseCase ?? getIt<PdfGenerateExecutiveUseCase>(),
        _pdfProfessional = pdfGenerateProfessionalUseCase ?? getIt<PdfGenerateProfessionalUseCase>(),
        _moneyConvert = convertCoinRepository ?? getIt<ConvertCoinRepository>(),
        _displayAlert = displayAlertRepository ?? getIt<DisplayAlertRepository>();

  final List<ItemsBudget> items;
  final CustomerInfo customer;
  final OwnerPdf owner;
  final List<ObservationPdf> observations;
  final String token;

  final PdfGenerateBudgetUsecase _pdfGenerateUseCase;
  final PdfGenerateExecutiveUseCase _pdfExecutive;
  final PdfGenerateProfessionalUseCase _pdfProfessional;
  final ConvertCoinRepository _moneyConvert;
  final DisplayAlertRepository _displayAlert;

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
          await _displayAlert.notificationWarning(
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
          final total = i.TOTAL ?? 0;
          if (i.CATEGORIA == 'Produtos') {
            totalProducts += total;
            countProduct++;
          } else if (i.CATEGORIA == 'Serviços') {
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
              totalPriceProducts: _moneyConvert.convertFromDouble(totalProducts),
              totalPriceServices: _moneyConvert.convertFromDouble(totalServices),
              items: List<ItemsBudget>.from(items),
              customer: customer,
              owner: owner,
              observations: List<ObservationPdf>.from(observations),
              authToken: token,
            );
          case 'professional':
            bytes = await _pdfProfessional.professionalPDFBytes(
              countService: countService,
              countProduct: countProduct,
              totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
              totalPriceProducts: _moneyConvert.convertFromDouble(totalProducts),
              totalPriceServices: _moneyConvert.convertFromDouble(totalServices),
              items: List<ItemsBudget>.from(items),
              customer: customer,
              owner: owner,
              observations: List<ObservationPdf>.from(observations),
              authToken: token,
            );
          default:
            bytes = await _pdfGenerateUseCase.patternPDFBytes(
              countService: countService,
              countProduct: countProduct,
              totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
              totalPriceProducts: _moneyConvert.convertFromDouble(totalProducts),
              totalPriceServices: _moneyConvert.convertFromDouble(totalServices),
              items: List<ItemsBudget>.from(items),
              customer: customer,
              owner: owner,
              observations: List<ObservationPdf>.from(observations),
              authToken: token,
            );
        }
        _bytes = bytes;
      }
    } catch (e) {
      if (context.mounted) {
        await _displayAlert.notificationWarning(
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
