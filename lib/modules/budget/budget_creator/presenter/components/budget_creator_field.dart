import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/modules/budget/budget_creator/presenter/budget_creator_view_model.dart';

class BudgetCreatorField extends StatelessWidget {
  const BudgetCreatorField({
    super.key,
    required this.field,
    required this.viewModel,
    required this.hintText,
    required this.prefixIcon,
    this.widthFactor = 0.8,
    this.heightFactor = 0.078,
    this.controller,
    this.focusNode,
    this.onTap,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.enableInteractiveSelection = false,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final Gender field;
  final BudgetCreatorViewModel viewModel;
  final String hintText;
  final IconData prefixIcon;
  final double widthFactor;
  final double heightFactor;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool enableInteractiveSelection;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<dynamic>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    final isSelected = viewModel.selected == field;

    return FadeAnimationWidget(
      delay: 1,
      child: Container(
        width: we * widthFactor,
        height: he * heightFactor,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: bgColor,
        ),
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onTap: onTap,
          onChanged: onChanged,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          enableInteractiveSelection: enableInteractiveSelection,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters?.cast(),
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            border: InputBorder.none,
            enabled: enabled,
            prefixIcon: Icon(
              prefixIcon,
              color: isSelected ? viewModel.enabledtxt : viewModel.deaible,
            ),
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
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
