import 'package:flutter/material.dart';
import 'presenter/singup_view.dart';

enum SingupRoute { singup }

extension SingupRouteExtension on SingupRoute {
  String get path {
    switch (this) {
      case SingupRoute.singup:
        return '/singup';
    }
  }
}

final Map<String, WidgetBuilder> singupRoutes = {
  SingupRoute.singup.path: (_) => const SingUpView(),
};
