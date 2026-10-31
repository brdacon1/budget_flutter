import 'package:flutter/material.dart';

enum CommentRoute { commentList }

extension CommentRouteExtension on CommentRoute {
  String get path {
    switch (this) {
      case CommentRoute.commentList:
        return '/budget/comments';
    }
  }
}

/// CommentListView exige [CustomerInfo] como parâmetro — por ora
/// a navegação continua via `MaterialPageRoute` (argumentos dinâmicos).
/// O enum fica disponível para uso futuro com `onGenerateRoute`.
final Map<String, WidgetBuilder> commentRoutes = {};
