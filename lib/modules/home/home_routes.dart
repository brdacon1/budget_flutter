import 'package:material_ui/material_ui.dart';

import 'presenter/home_view.dart';

enum HomeRoute { home }

extension HomeRouteExtension on HomeRoute {
  String get path {
    switch (this) {
      case HomeRoute.home:
        return '/home';
    }
  }
}

final Map<String, WidgetBuilder> homeRoutes = {
  HomeRoute.home.path: (_) => const HomeView(),
};
