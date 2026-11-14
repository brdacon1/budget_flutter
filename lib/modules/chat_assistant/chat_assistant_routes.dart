import 'package:material_ui/material_ui.dart';
import 'presenter/chat_assistant/chat_assistant_view.dart';

enum ChatBudgetRoute { chatAssistant }

extension ChatBudgetRouteExtension on ChatBudgetRoute {
  String get path {
    switch (this) {
      case ChatBudgetRoute.chatAssistant:
        return '/assistant';
    }
  }
}

final Map<String, WidgetBuilder> chatBudgetRoutes = {
  ChatBudgetRoute.chatAssistant.path: (_) => const ChatAssistantView(),
};
