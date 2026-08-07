import 'package:flutter/material.dart';
import 'package:oflite/Services/http_request.dart';
import 'package:oflite/Services/display_alert.dart';
import 'package:oflite/services/convert_coin.dart';
import '../../../services/pdf_generate.dart';

class PdfBudgetViewModel extends ChangeNotifier {
  final HttpRequest db = HttpRequest();
  final DisplayAlert displayAlert = DisplayAlert();
  final ConvertCoin moneyConvert = ConvertCoin();
  final PdfGenerate pdf = PdfGenerate();
  String? fileBytes;
  bool _loading = true;
  bool get loading => _loading;
  PdfBudgetViewModel();

  Future<void> initialData(BuildContext context) async {
    _loading = true;
    notifyListeners();
    try {
      final budget = await db.getListItensGerador();
      final customer = await db.getInformationOrcamento1();
      final owner = await db.getInformationEnterprise();
      final comment = await db.getListComentarioPDF();

      if (budget.isNotEmpty) {
        double totalProducts = 0;
        double totalServices = 0;
        double totalBudget = 0;
        int countProduct = 0;
        int countService = 0;

        for (int index = 0; index < budget.length; index++) {
          final total = budget[index].TOTAL ?? 0;
          if (budget[index].CATEGORIA == 'Produtos') {
            totalProducts += total;
            countProduct++;
          } else if (budget[index].CATEGORIA == 'Serviços') {
            totalServices += total;
            countService++;
          }
          totalBudget += total;
        }

        final generated = await pdf.patternPDF(
          countService,
          countProduct,
          moneyConvert.convertFromDouble(totalBudget),
          moneyConvert.convertFromDouble(totalProducts),
          moneyConvert.convertFromDouble(totalServices),
          budget,
          customer,
          owner,
          comment,
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
      notifyListeners();
    }
  }

  Future<void> refresh(BuildContext context) => initialData(context);
}
