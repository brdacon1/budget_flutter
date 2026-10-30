import 'package:flutter/material.dart';

import 'presenter/dashboard_view.dart';

enum DashboardRoute {
  dashboard,
}

extension DashboardRouteExtension on DashboardRoute {
  String get path {
    switch (this) {
      case DashboardRoute.dashboard:
        return '/dashboard';
    }
  }
}

final Map<String, WidgetBuilder> dashboardRoutes = {
  DashboardRoute.dashboard.path: (_) => const DashboardView(),
};
