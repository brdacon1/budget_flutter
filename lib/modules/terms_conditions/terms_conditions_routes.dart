import 'package:flutter/material.dart';
import 'presenter/terms_conditions_view.dart';

enum TermsConditionsRoute { termsConditions }

extension TermsConditionsRouteExtension on TermsConditionsRoute {
  String get path {
    switch (this) {
      case TermsConditionsRoute.termsConditions:
        return '/terms-and-conditions';
    }
  }
}

final Map<String, WidgetBuilder> termsConditionsRoutes = {
  TermsConditionsRoute.termsConditions.path: (_) => const TermsConditionsView(),
};
