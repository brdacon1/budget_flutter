import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';

// ---------------------------------------------------------------------------
// Input que mostra estado de edição inline (estilo WhatsApp)
// ---------------------------------------------------------------------------

class ChatEditAwareInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;
  final bool enabled;
  final bool isEditing;

  /// "+" de anexos (só modo IA). `null` esconde o botão.
  final VoidCallback? onAttach;

  const ChatEditAwareInputBar({
    super.key,
    this.onAttach,
    required this.controller,
    required this.onSend,
    required this.onCancelEdit,
    this.focusNode,
    this.enabled = true,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: chatBarColor,
        border: Border(top: BorderSide(color: chatDividerColor)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 14, color: chatHighlightColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ChatAssistantStrings.editingMessageTitle,
                        style: const TextStyle(
                          color: chatHighlightColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelEdit,
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: chatMutedIconColor,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (onAttach != null && !isEditing)
                  IconButton(
                    onPressed: enabled ? onAttach : null,
                    tooltip: PaymentProofStrings.attach,
                    icon: const Icon(Icons.add, color: whiteColor, size: 28),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: whiteColor),
                    decoration: InputDecoration(
                      hintText:
                          isEditing
                              ? ChatAssistantStrings.editMessageHint
                              : ChatAssistantStrings.typeMessageHint,
                      hintStyle: TextStyle(color: chatHintColor),
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
                const SizedBox(width: 6),
                Material(
                  color: chatSendButtonColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? onSend : null,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.send, color: blackColor, size: 20),
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
