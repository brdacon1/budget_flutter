import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Campo de formulário com label sempre visível (ARCHITECTURE §17.3).
class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    required this.label,
    required this.prefixIcon,
    required this.controller,
    this.hintText,
    this.focusNode,
    this.suffix,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String? hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Widget? suffix;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 12),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          // Ao focar, rola o campo até perto do centro da área visível
          // (acima do teclado + barra de fechar teclado) — §17.8.
          scrollPadding: EdgeInsets.only(
            bottom: MediaQuery.sizeOf(context).height * 0.3,
          ),
          onChanged: onChanged,
          onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          cursorColor: buttonColor,
          style: GoogleFonts.heebo(
            color: whiteColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: bgColor,
            hintText: hintText,
            hintStyle: GoogleFonts.heebo(color: slateGray, fontSize: 15),
            prefixIcon: Icon(prefixIcon, color: mutedTextColor, size: 20),
            suffixIcon: suffix,
            errorText: errorText,
            errorStyle: GoogleFonts.heebo(
              color: statusRejectedColor,
              fontSize: 12,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: statusRejectedColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: statusRejectedColor,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: sheetHandleColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: buttonColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
