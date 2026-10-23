import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/shared/models/observation_pdf.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/usecases/data/usecase/pdf_generate_usecase.dart';

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
  });

  final List<ItemsBudget> items;
  final CustomerInfo customer;
  final OwnerPdf owner;
  final List<ObservationPdf> observations;
  final String token;

  final PdfGenerateUseCase _pdf = PdfGenerateUseCase();
  final ConvertCoin moneyConvert = ConvertCoin();
  final DisplayAlert _displayAlert = DisplayAlert();

  Uint8List? _bytes;
  Uint8List? get bytes => _bytes;

  bool _loading = true;
  bool get loading => _loading;

  bool _disposed = false;
  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> inicialData(BuildContext context) async {
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
        _bytes = await _pdf.patternPDFBytes(
          countService: countService,
          countProduct: countProduct,
          totalPriceBudget: moneyConvert.convertFromDouble(totalBudget),
          totalPriceProducts: moneyConvert.convertFromDouble(totalProducts),
          totalPriceServices: moneyConvert.convertFromDouble(totalServices),
          items: List<ItemsBudget>.from(items),
          customer: customer,
          owner: owner,
          observations: List<ObservationPdf>.from(observations),
          authToken: token,
        );
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
