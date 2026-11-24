import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Miniatura com lápis à esquerda da legenda (igual WhatsApp): abre o recorte.
class ChatCropThumbButton extends StatelessWidget {
  const ChatCropThumbButton({
    super.key,
    required this.image,
    required this.onTap,
    this.busy = false,
  });

  final ImageProvider? image;
  final VoidCallback onTap;

  /// Carregando o recorte: mostra spinner e ignora toques.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: PaymentProofStrings.cropTitle,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  Image(image: image!, fit: BoxFit.cover)
                else
                  const ColoredBox(color: secondaryColor),
                ColoredBox(color: blackColor.withValues(alpha: 0.35)),
                if (busy)
                  const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: whiteColor,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.crop_rotate, color: whiteColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
