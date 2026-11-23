import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

// ---------------------------------------------------------------------------
// Formulário de endereço manual (com suporte a correção de CEP)
// ---------------------------------------------------------------------------

class ChatManualAddressForm extends StatelessWidget {
  final TextEditingController streetController;
  final TextEditingController numberController;
  final TextEditingController cityController;
  final TextEditingController neighborhoodController;
  final TextEditingController? cepController;
  final bool isCorrecting;
  final VoidCallback onSubmit;
  final VoidCallback onCancelAndProceed;

  const ChatManualAddressForm({
    super.key,
    required this.streetController,
    required this.numberController,
    required this.cityController,
    required this.neighborhoodController,
    this.cepController,
    required this.isCorrecting,
    required this.onSubmit,
    required this.onCancelAndProceed,
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
            if (isCorrecting)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: chatHighlightColor),
                      foregroundColor: chatHighlightColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onCancelAndProceed,
                    child: Text(
                      ChatAssistantStrings.cancelAndProceed,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildField(
                    streetController,
                    ChatAssistantStrings.streetField,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _buildField(
                    numberController,
                    ChatAssistantStrings.numberField,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (isCorrecting && cepController != null) ...[
              const SizedBox(height: 8),
              _buildField(
                cepController!,
                ChatAssistantStrings.cepField,
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 8),
            _buildField(cityController, ChatAssistantStrings.cityField),
            const SizedBox(height: 8),
            _buildField(
              neighborhoodController,
              ChatAssistantStrings.neighborhoodField,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: chatSendButtonColor,
                  foregroundColor: blackColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onSubmit,
                child: Text(
                  ChatAssistantStrings.confirmAddressButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: whiteColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: chatHintColor),
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
    );
  }
}
