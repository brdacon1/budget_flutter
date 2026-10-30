import 'package:flutter/material.dart';

enum PaymentRoute { paymentList, paymentCreator }

extension PaymentRouteExtension on PaymentRoute {
  String get path {
    switch (this) {
      case PaymentRoute.paymentList:
        return '/payment/list';
      case PaymentRoute.paymentCreator:
        return '/payment/create';
    }
  }
}

/// As telas do módulo Payment exigem [CustomerInfo], [Receipt] ou
/// [PaymentCustomer] como parâmetros — navegação via `MaterialPageRoute`.
final Map<String, WidgetBuilder> paymentRoutes = {};
