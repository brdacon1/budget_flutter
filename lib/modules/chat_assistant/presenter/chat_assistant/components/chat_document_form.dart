import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

// ---------------------------------------------------------------------------
// Formulário de CNPJ / CPF da empresa (fluxo "Editar PDF")
// ---------------------------------------------------------------------------

class ChatDocumentForm extends StatelessWidget {
  final TextEditingController controller;
  final TextInputFormatter formatter;
  final String? errorText;
  final bool isSaving;
  final ValueChanged<String>? onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const ChatDocumentForm({
    super.key,
    required this.controller,
    required this.formatter,
    required this.onSubmit,
    required this.onCancel,
    this.errorText,
    this.isSaving = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: chatBarColor,
        border: Border(top: BorderSide(color: chatDividerColor)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              inputFormatters: [formatter],
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
              style: const TextStyle(color: whiteColor),
              decoration: InputDecoration(
                hintText: ChatAssistantStrings.documentFormHint,
                hintStyle: TextStyle(color: chatHintColor),
                errorText: errorText,
                filled: true,
                fillColor: secondaryColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: chatHighlightColor),
                      foregroundColor: chatHighlightColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isSaving ? null : onCancel,
                    child: Text(
                      ChatAssistantStrings.documentFormCancel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: chatSendButtonColor,
                      foregroundColor: blackColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isSaving ? null : onSubmit,
                    child: Text(
                      ChatAssistantStrings.documentFormSave,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
