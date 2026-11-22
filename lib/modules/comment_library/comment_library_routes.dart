import 'package:material_ui/material_ui.dart';

import 'presenter/comment_library_list/comment_library_list_view.dart';

enum CommentLibraryRoute { commentLibraryList }

extension CommentLibraryRouteExtension on CommentLibraryRoute {
  String get path => switch (this) {
    CommentLibraryRoute.commentLibraryList => '/comment-library/list',
  };
}

/// O creator e o picker são modais (`show…BottomModal`), não rotas.
final Map<String, WidgetBuilder> commentLibraryRoutes = {
  CommentLibraryRoute.commentLibraryList.path:
      (_) => const CommentLibraryListView(),
};
