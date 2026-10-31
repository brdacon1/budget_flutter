import 'package:flutter/material.dart';
import 'presenter/subscription_view.dart';

enum SubscriptionRoute { subscription }

extension SubscriptionRouteExtension on SubscriptionRoute {
  String get path {
    switch (this) {
      case SubscriptionRoute.subscription:
        return '/pg-subscription';
    }
  }
}

final Map<String, WidgetBuilder> subscriptionRoutes = {
  SubscriptionRoute.subscription.path: (_) => const SubscriptionView(),
};
