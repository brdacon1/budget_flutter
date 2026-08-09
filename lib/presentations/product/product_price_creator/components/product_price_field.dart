import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';

/// Campo de formulário reutilizável da tela de produto/serviço.
///
/// Encapsula o `Container` arredondado + `TextField` estilizado que se repete
/// para categoria, unidade, preço, quantidade e descrição — todas com a mesma
/// aparência (fundo `bgColor`, ícone à esquerda, hint cinza, texto branco
/// negrito). `StatelessWidget` puro: recebe controller, hint, ícone e
/// callbacks, sem conhecer o ViewModel nem services.
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
    this.widthFactor = 0.80,
    this.heightFactor = 0.078,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final double widthFactor;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;

    return FadeAnimationWidget(
      delay: 1,
      child: Container(
        width: we * widthFactor,
        height: maxLines == null ? he * heightFactor : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: bgColor,
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
            prefixIcon: Icon(icon, color: whiteColor),
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
