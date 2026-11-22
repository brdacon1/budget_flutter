import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Campo do modal de comentário no padrão dos bottom modals (fundo branco,
/// borda cinza), com label visível, erro inline e contador opcional.
class CommentLibraryTextField extends StatelessWidget {
  const CommentLibraryTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.errorText,
    this.maxLength,
    this.multiline = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? errorText;
  final int? maxLength;
  final bool multiline;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppBottomModal.grayColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError ? Colors.red.shade700 : const Color(0xFF9E9E9E),
              width: 2,
            ),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType:
                multiline ? TextInputType.multiline : TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            minLines: multiline ? 5 : 1,
            maxLines: multiline ? 10 : 1,
            maxLength: maxLength,
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.3,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            style: const TextStyle(
              color: AppBottomModal.grayColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              errorText!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
