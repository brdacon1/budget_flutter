import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/support/presenter/strings/support_pt_string.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportViewModel extends ChangeNotifier {
  /// Número do WhatsApp do suporte: só dígitos, com DDI (55) + DDD.
  /// Para trocar, altere aqui e faça o deploy do Web.
  static const String whatsappNumber = '5515997861271';

  /// Número formatado para exibição.
  String get displayNumber => '+55 (15) 99786-1271';

  Future<void> openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(SupportPtString.whatsappMessage)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
