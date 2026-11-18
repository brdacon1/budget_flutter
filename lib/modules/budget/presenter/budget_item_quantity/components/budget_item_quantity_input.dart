import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Campo de quantidade em destaque (label visível + erro inline, §17.3/§17.4).
class BudgetItemQuantityInput extends StatelessWidget {
  const BudgetItemQuantityInput({
    super.key,
    required this.label,
    required this.controller,
    required this.measure,
    required this.errorText,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String measure;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.heebo(
            color: AppBottomModal.grayColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted(),
          cursorColor: AppBottomModal.grayColor,
          style: GoogleFonts.heebo(
            color: AppBottomModal.grayColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            isDense: true,
            suffixText: measure.isEmpty ? null : measure,
            suffixStyle: GoogleFonts.heebo(
              color: modalLabelColor,
              fontSize: 15,
            ),
            errorText: errorText,
            errorStyle: GoogleFonts.heebo(
              color: statusRejectedColor,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: _border(buttonColor, 2),
            focusedBorder: _border(buttonColor, 2.5),
            errorBorder: _border(statusRejectedColor, 2),
            focusedErrorBorder: _border(statusRejectedColor, 2.5),
          ),
        ),
      ],
    );
  }
}
