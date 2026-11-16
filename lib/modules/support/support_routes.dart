import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/support/presenter/support_view.dart';

enum SupportRoute { support }

extension SupportRouteExtension on SupportRoute {
  String get path {
    switch (this) {
      case SupportRoute.support:
        return '/support';
    }
  }
}

final Map<String, WidgetBuilder> supportRoutes = {
  SupportRoute.support.path: (_) => const SupportView(),
};
