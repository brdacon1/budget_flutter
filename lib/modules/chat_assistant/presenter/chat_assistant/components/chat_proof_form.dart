import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/invoice/presenter/strings/invoice_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Formulário do comprovante (só valor) e da nota fiscal (nome e valor) — mesmo visual do `ChatDocumentForm` (Editar PDF).
class ChatProofForm extends StatelessWidget {
  final bool isInvoice;
  final TextEditingController nameController;
  final MoneyMaskedTextController valueController;
  final String? errorText;
  final bool isSaving;
  final ValueChanged<String>? onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const ChatProofForm({
    super.key,
    required this.isInvoice,
    required this.nameController,
    required this.valueController,
    required this.onSubmit,
    required this.onCancel,
    this.errorText,
    this.isSaving = false,
    this.onChanged,
  });

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: chatHintColor),
    filled: true,
    fillColor: secondaryColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );

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
            if (isInvoice) ...[
              TextField(
                controller: nameController,
                onChanged: onChanged,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: whiteColor),
                decoration: _decoration(InvoiceStrings.fieldName),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: valueController,
              autofocus: true,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: whiteColor),
              decoration: _decoration(InvoiceStrings.fieldValue),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  errorText!,
                  style: const TextStyle(
                    color: statusRejectedColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
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
                      InvoiceStrings.back,
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
                      InvoiceStrings.save,
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
