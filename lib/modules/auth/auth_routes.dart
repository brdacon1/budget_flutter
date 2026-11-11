import 'package:flutter/material.dart';

import 'presenter/login/login_view.dart';

enum AuthRoute { login, singup }

extension AuthRouteExtension on AuthRoute {
  String get path {
    switch (this) {
      case AuthRoute.login:
        return '/';
      case AuthRoute.singup:
        return '/singup';
    }
  }
}

final Map<String, WidgetBuilder> loginRoutes = {
  AuthRoute.login.path: (_) => const LoginView(),
};
