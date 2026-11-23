import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

enum ChatAttachmentChoice { photos, camera, document }

/// Painel de anexos do "+" (estilo WhatsApp): Fotos, Câmera, Documento.
/// Abre em modal pelo navigator raiz, cobrindo a tab bar.
class ChatAttachmentPanel extends StatelessWidget {
  const ChatAttachmentPanel({super.key});

  static Future<ChatAttachmentChoice?> show(BuildContext context) =>
      showModalBottomSheet<ChatAttachmentChoice>(
        context: context,
        useRootNavigator: true,
        backgroundColor: transparentColor,
        builder: (_) => const ChatAttachmentPanel(),
      );

  @override
  Widget build(BuildContext context) {
    void pick(ChatAttachmentChoice c) => Navigator.pop(context, c);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: sheetHandleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Option(
                  icon: Icons.photo_library_rounded,
                  color: primaryColor,
                  label: PaymentProofStrings.attachPhotos,
                  onTap: () => pick(ChatAttachmentChoice.photos),
                ),
                _Option(
                  icon: Icons.photo_camera_rounded,
                  color: whiteColor,
                  label: PaymentProofStrings.attachCamera,
                  onTap: () => pick(ChatAttachmentChoice.camera),
                ),
                _Option(
                  icon: Icons.insert_drive_file_rounded,
                  color: primaryColor,
                  label: PaymentProofStrings.attachDocument,
                  onTap: () => pick(ChatAttachmentChoice.document),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: darkSlate,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: whiteColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
