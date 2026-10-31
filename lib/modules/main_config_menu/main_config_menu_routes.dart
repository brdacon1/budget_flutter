import 'package:flutter/material.dart';

import 'presenter/main_config_menu_view.dart';

enum MainConfigMenuRoute {
  mainConfigMenu,
}

extension MainConfigMenuRouteExtension on MainConfigMenuRoute {
  String get path {
    switch (this) {
      case MainConfigMenuRoute.mainConfigMenu:
        return '/main-config-menu';
    }
  }
}

final Map<String, WidgetBuilder> mainConfigMenuRoutes = {
  MainConfigMenuRoute.mainConfigMenu.path: (_) => const MainConfigMenuView(),
};
