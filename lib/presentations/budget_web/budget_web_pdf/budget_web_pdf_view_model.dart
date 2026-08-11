import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:oflite/common/strings/budget_web_strings.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/models/observation_pdf.dart';
import 'package:oflite/models/owner_pdf.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/usecases/pdf_generate_usecase.dart';

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
        _bytes = await _pdf.patternPDFBytes(
          countService: countService,
          countProduct: countProduct,
          totalPriceBudget: moneyConvert.convertFromDouble(totalBudget),
          totalPriceProducts: moneyConvert.convertFromDouble(totalProducts),
          totalPriceServices: moneyConvert.convertFromDouble(totalServices),
          items: items,
          customer: customer,
          owner: owner,
          observations: observations,
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
