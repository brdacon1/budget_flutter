import 'package:flutter/material.dart';
import 'package:oflite/modules/auth/presenter/login/login_view_model.dart';
import 'package:oflite/shared/common/constants/constants.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.field,
    required this.controller,
    required this.labelText,
    required this.viewModel,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  final LoginField field;
  final TextEditingController controller;
  final String labelText;
  final LoginViewModel viewModel;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final isSelected = viewModel.selectedField == field;

    return TextField(
      controller: controller,
      onTap: () => viewModel.selectField(field),
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: isSelected ? viewModel.enabledtxt : viewModel.deaible,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: buttonColor,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isSelected
                ? viewModel.enabledtxt.withValues(alpha: 0.3)
                : viewModel.deaible.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: buttonColor),
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: TextStyle(
        color: isSelected ? viewModel.enabledtxt : viewModel.deaible,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
