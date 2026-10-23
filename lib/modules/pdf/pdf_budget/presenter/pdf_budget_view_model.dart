import 'package:flutter/material.dart';
import 'package:oflite/modules/core/services/data/service/http_request.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/usecases/data/usecase/pdf_generate_usecase.dart';

class PdfBudgetViewModel extends ChangeNotifier {
  final HttpRequest db = HttpRequest();
  final DisplayAlert displayAlert = DisplayAlert();
  final ConvertCoin moneyConvert = ConvertCoin();
  final PdfGenerateUseCase pdf = PdfGenerateUseCase();
  String? fileBytes;
  bool _loading = true;
  bool get loading => _loading;
  /// `true` após [dispose] — evita chamar `notifyListeners()` (e usar o VM)
  /// depois que a View foi descartada, o que lançaria
  /// `A PdfBudgetViewModel was used after being disposed`.
  bool _disposed = false;
  PdfBudgetViewModel();

  /// Notifica apenas se o VM ainda estiver vivo. Silenciosamente ignora
  /// notificações que chegam após [dispose] (ex.: retornos de `await` de uma
  /// `initialData` que ainda estava rodando quando a tela foi fechada).
  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> initialData(BuildContext context) async {
    _loading = true;
    _safeNotify();
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
          countService: countService,
          countProduct: countProduct,
          totalPriceBudget: moneyConvert.convertFromDouble(totalBudget),
          totalPriceProducts: moneyConvert.convertFromDouble(totalProducts),
          totalPriceServices: moneyConvert.convertFromDouble(totalServices),
          items: budget,
          customer: customer,
          owner: owner,
          observations: comment,
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
