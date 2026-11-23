import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Painel de detalhe do assistente (tela larga) enquanto nada foi aberto.
class ChatEmptyDetail extends StatelessWidget {
  const ChatEmptyDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              color: emptyStateIconColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                ChatAssistantStrings.emptyDetailHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.heebo(
                  color: loadingIndicatorColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
