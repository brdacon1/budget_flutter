import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalViewModel extends ChangeNotifier {
  /// Navega para outra página legal recarregando a URL real do navegador
  /// (o `main_web.dart` escolhe a tela pelo path).
  Future<void> open(String path) async {
    await launchUrl(Uri.base.resolve(path), webOnlyWindowName: '_self');
  }
}
