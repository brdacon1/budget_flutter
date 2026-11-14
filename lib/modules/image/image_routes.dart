import 'package:material_ui/material_ui.dart';

enum ImageRoute { imageEdit }

extension ImageRouteExtension on ImageRoute {
  String get path {
    switch (this) {
      case ImageRoute.imageEdit:
        return '/image/edit';
    }
  }
}

/// ImageEditView exige parâmetros ([title] e [owner]) — por ora
/// a navegação continua via `MaterialPageRoute`.
final Map<String, WidgetBuilder> imageRoutes = {};
