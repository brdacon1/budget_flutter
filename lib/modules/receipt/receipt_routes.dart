import 'package:flutter/material.dart';

enum ReceiptRoute { receiptList, receiptCreator, receiptTab }

extension ReceiptRouteExtension on ReceiptRoute {
  String get path {
    switch (this) {
      case ReceiptRoute.receiptList:
        return '/receipt/list';
      case ReceiptRoute.receiptCreator:
        return '/receipt/create';
      case ReceiptRoute.receiptTab:
        return '/receipt/tab';
    }
  }
}

/// As telas do módulo Receipt exigem [CustomerInfo] e/ou [Receipt]
/// como parâmetros — navegação via `MaterialPageRoute`.
final Map<String, WidgetBuilder> receiptRoutes = {};
