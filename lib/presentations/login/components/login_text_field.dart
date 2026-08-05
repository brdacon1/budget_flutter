import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/presentations/login/login_view_model.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.field,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.viewModel,
    required this.width,
    required this.height,
    this.obscureText = false,
    this.suffixIcon,
  });

  final LoginField field;
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final LoginViewModel viewModel;
  final double width;
  final double height;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final isSelected = viewModel.selectedField == field;

    return FadeAnimationWidget(
      delay: 1,
      child: Container(
        width: width * 0.9,
        height: height * 0.082,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: secondaryColor, width: 2),
          color: isSelected ? viewModel.enabled : bgColor,
        ),
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: controller,
          onTap: () => viewModel.selectField(field),
          obscureText: obscureText,
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            border: InputBorder.none,
            prefixIcon: Icon(
              prefixIcon,
              color: isSelected ? viewModel.enabledtxt : viewModel.deaible,
            ),
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: TextStyle(
              color: isSelected ? viewModel.enabledtxt : viewModel.deaible,
            ),
          ),
          style: TextStyle(
            color: isSelected ? viewModel.enabledtxt : viewModel.deaible,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
