import 'package:flutter/material.dart';
import 'pdf_edit/presenter/pdf_edit_view.dart';

enum PdfRoute { pdfConfig }

extension PdfRouteExtension on PdfRoute {
  String get path {
    switch (this) {
      case PdfRoute.pdfConfig:
        return '/pg-pdf-config';
    }
  }
}

final Map<String, WidgetBuilder> pdfRoutes = {
  PdfRoute.pdfConfig.path: (_) => const PdfEditView(),
};
