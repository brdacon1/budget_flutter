import 'package:flutter/material.dart';
import 'presenter/login_view.dart';

enum LoginRoute { login }

extension LoginRouteExtension on LoginRoute {
  String get path {
    switch (this) {
      case LoginRoute.login:
        return '/';
    }
  }
}

final Map<String, WidgetBuilder> loginRoutes = {
  LoginRoute.login.path: (_) => const LoginView(),
};
