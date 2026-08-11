import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';

/// Campo de telefone da tela de validação Web — visual compatível com os
/// campos do app mobile (campo estilizado com prefixo e label branca).
class BudgetWebAuthField extends StatelessWidget {
  const BudgetWebAuthField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.maskFormatter,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final dynamic maskFormatter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [maskFormatter],
        style: GoogleFonts.heebo(
          color: whiteColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.phone_android_outlined, color: whiteColor),
          hintText: 'Telefone',
          hintStyle: GoogleFonts.heebo(color: Colors.white54),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
