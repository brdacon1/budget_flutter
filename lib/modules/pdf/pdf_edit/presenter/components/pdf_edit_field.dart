import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/pdf/pdf_edit/presenter/pdf_edit_view_model.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';

class PdfEditField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Gender gender;
  final Color enabledColor;
  final Color disabledColor;
  final Gender? selected;
  final MaskTextInputFormatter? mask;
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
  });

  Color get _color => selected == gender ? enabledColor : disabledColor;

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    return FadeAnimationWidget(
      delay: 1,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: he * 0.071,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: bgColor,
        ),
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
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
      ),
    );
  }
}
