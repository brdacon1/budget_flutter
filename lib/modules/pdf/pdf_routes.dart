import 'package:flutter/material.dart';
import 'pdf_budget/presenter/pdf_budget_view.dart';
import 'pdf_edit/presenter/pdf_edit_view.dart';

enum PdfRoute {
  pdfConfig,
  pdfBudget,
  pdfEdit,
  pdfReceipt,
  pdfMenu,
}

extension PdfRouteExtension on PdfRoute {
  String get path {
    switch (this) {
      case PdfRoute.pdfConfig:
        return '/pg-pdf-config';
      case PdfRoute.pdfBudget:
        return '/pdf/budget';
      case PdfRoute.pdfEdit:
        return '/pdf/edit';
      case PdfRoute.pdfReceipt:
        return '/pdf/receipt';
      case PdfRoute.pdfMenu:
        return '/pdf/menu';
    }
  }
}

/// Telas sem argumentos expostas como rotas nomeadas.
/// PdfMenuView e PdfReceiptView exigem [CustomerInfo] / [Receipt] —
/// navegação via `MaterialPageRoute`.
final Map<String, WidgetBuilder> pdfRoutes = {
  PdfRoute.pdfConfig.path: (_) => const PdfEditView(),
  PdfRoute.pdfBudget.path: (_) => const PdfBudgetView(),
  PdfRoute.pdfEdit.path: (_) => const PdfEditView(),
};
