import 'package:flutter/material.dart';
import 'package:oflite/modules/delete_account/presenter/delete_account_view.dart';

enum DeleteAccountRoute { deleteAccount }

extension DeleteAccountRouteExtension on DeleteAccountRoute {
  String get path {
    switch (this) {
      case DeleteAccountRoute.deleteAccount:
        return '/delete-account';
    }
  }
}

final Map<String, WidgetBuilder> deleteAccountRoutes = {
  DeleteAccountRoute.deleteAccount.path: (_) => const DeleteAccountView(),
};
