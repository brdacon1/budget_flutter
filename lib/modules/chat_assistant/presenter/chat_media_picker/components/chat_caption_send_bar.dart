import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Barra inferior: legenda + botão enviar com contador (print 2).
class ChatCaptionSendBar extends StatelessWidget {
  const ChatCaptionSendBar({
    super.key,
    required this.controller,
    required this.count,
    required this.onSend,
    this.sending = false,
    this.leading,
  });

  final TextEditingController controller;
  final int count;
  final VoidCallback onSend;
  final bool sending;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cartBarColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: whiteColor),
                decoration: InputDecoration(
                  hintText: PaymentProofStrings.captionHint,
                  hintStyle: const TextStyle(color: mutedTextColor),
                  filled: true,
                  fillColor: secondaryColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: cartAccentColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: sending ? null : onSend,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child:
                          sending
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: blackColor,
                                ),
                              )
                              : const Icon(Icons.send, color: blackColor),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: cartAccentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: cartBarColor, width: 2),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: blackColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
