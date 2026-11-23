import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Texto do comentário no modal escuro: leitura (texto puro) ou edição
/// (campo multilinha com erro inline).
class BudgetCommentDetailTextField extends StatelessWidget {
  const BudgetCommentDetailTextField({
    super.key,
    required this.controller,
    required this.editing,
    required this.enabled,
    this.errorText,
  });

  final TextEditingController controller;
  final bool editing;
  final bool enabled;
  final String? errorText;

  static const _style = TextStyle(color: whiteColor, fontSize: 15, height: 1.4);

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SelectableText(controller.text, style: _style),
      );
    }
    final hasError = errorText != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        autofocus: true,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        minLines: 4,
        maxLines: 10,
        maxLength: 1000,
        cursorColor: buttonColor,
        style: _style,
        scrollPadding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.3,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: bgColor,
          errorText: errorText,
          counterStyle: const TextStyle(color: mutedTextColor),
          contentPadding: const EdgeInsets.all(14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError ? statusRejectedColor : cardBorderColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError ? statusRejectedColor : buttonColor,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: statusRejectedColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: statusRejectedColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
