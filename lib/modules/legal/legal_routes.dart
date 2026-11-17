import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/legal/presenter/legal_view.dart';
import 'package:oflite/modules/legal/presenter/strings/legal_en_string.dart';
import 'package:oflite/modules/legal/presenter/strings/legal_pt_string.dart';

/// Páginas legais públicas (Web). O idioma vem da URL, não do navegador,
/// para que cada link cadastrado na App Store/Play Store seja estável.
enum LegalRoute { termsPt, privacyPt, termsEn, privacyEn }

extension LegalRouteExtension on LegalRoute {
  String get path {
    switch (this) {
      case LegalRoute.termsPt:
        return '/termos-de-uso';
      case LegalRoute.privacyPt:
        return '/politica-de-privacidade';
      case LegalRoute.termsEn:
        return '/terms-of-use';
      case LegalRoute.privacyEn:
        return '/privacy-policy';
    }
  }

  Widget get view {
    switch (this) {
      case LegalRoute.termsPt:
        return const LegalView(document: LegalPtString.terms);
      case LegalRoute.privacyPt:
        return const LegalView(document: LegalPtString.privacy);
      case LegalRoute.termsEn:
        return const LegalView(document: LegalEnString.terms);
      case LegalRoute.privacyEn:
        return const LegalView(document: LegalEnString.privacy);
    }
  }
}

final Map<String, WidgetBuilder> legalRoutes = {
  for (final route in LegalRoute.values) route.path: (_) => route.view,
};
