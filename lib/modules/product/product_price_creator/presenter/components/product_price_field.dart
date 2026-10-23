import 'package:flutter/material.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Campo de formulário reutilizável do modal de produto/serviço.
///
/// Segue o **padrão visual dos bottom modals** do app (ver
/// `singup_field.dart` / `change_password_bottom_modal_widget.dart`):
/// - fundo **branco**;
/// - borda cinza `0xFF9E9E9E` (espessura 2);
/// - texto, ícone e hint em [AppBottomModal.grayColor] (cinza máximo);
/// - ocupa a largura total (auto-height).
///
/// Component `Stateless` puro — recebe dados (`controller`, `hintText`,
/// `icon`) e callbacks (`onTap`), sem conhecer o ViewModel nem services.
/// Suporta `readOnly` (campo de seleção), `suffixIcon` (indicador de dropdown)
/// e `maxLines` (descrição multilinha).
class ProductPriceField extends StatelessWidget {
  const ProductPriceField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.onTap,
    this.readOnly = false,
    this.suffixIcon,
    this.keyboardType,
    this.maxLines,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return FadeAnimationWidget(
      delay: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 2),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          enableInteractiveSelection: true,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onTap: onTap,
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: AppBottomModal.grayColor),
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          style: const TextStyle(
            color: AppBottomModal.grayColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
