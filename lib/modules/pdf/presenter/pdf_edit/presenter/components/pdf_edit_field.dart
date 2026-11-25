import 'package:oflite/modules/pdf/presenter/pdf_edit/presenter/enum/gender_enum.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:oflite/shared/common/constants/colors.dart';


class PdfEditField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Gender gender;
  final Color enabledColor;
  final Color disabledColor;
  final Gender? selected;
  final TextInputFormatter? mask;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  const PdfEditField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.gender,
    required this.enabledColor,
    required this.disabledColor,
    this.selected,
    this.mask,
    this.keyboardType,
    this.onTap,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  Color get _color => selected == gender ? enabledColor : disabledColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: bgColor,
      ),
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: mask != null ? [mask!] : null,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: _color),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        style: TextStyle(color: _color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
