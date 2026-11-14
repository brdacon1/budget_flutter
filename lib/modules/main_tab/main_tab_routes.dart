import 'package:material_ui/material_ui.dart';
import 'presenter/main_tab_view.dart';

enum MainTabRoute { mainTab }

extension MainTabRouteExtension on MainTabRoute {
  String get path {
    switch (this) {
      case MainTabRoute.mainTab:
        return '/menu';
    }
  }
}

final Map<String, WidgetBuilder> mainTabRoutes = {
  MainTabRoute.mainTab.path: (_) => const MainTabView(),
};
