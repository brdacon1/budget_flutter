import 'package:flutter/material.dart';
import 'presenter/login/login_view.dart';

enum LoginRoute { login,  singup}

extension LoginRouteExtension on LoginRoute {
  String get path {
    switch (this) {
      case LoginRoute.login:
        return '/';
      case LoginRoute.singup:
        return '/singup';
    }
  }
}

final Map<String, WidgetBuilder> loginRoutes = {
  LoginRoute.login.path: (_) => const LoginView(),
};
