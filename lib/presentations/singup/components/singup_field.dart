import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/enums/singup_field_enum.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';

/// Campo de texto estilizado reutilizável da tela de cadastro.
///
/// Component `Stateless` puro — recebe dados (`controller`, `hintText`, `icon`,
/// `field`, cores, `selected`, `isPassword`) e callbacks (`onTap`,
/// `togglePassword`). Não acessa services nem o ViewModel. É deliberadamente
/// análogo ao `pdf_edit_field` e `budget_creator_field`, seguindo o padrão de
/// referência.
class SingUpField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final SingUpFieldType field;
  final SingUpFieldType? selected;
  final Color enabledColor;
  final Color enabledTextColor;
  final Color disabledColor;
  final bool isPassword;
  final bool ispasswordev;
  final VoidCallback? onTap;
  final VoidCallback? togglePassword;

  const SingUpField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.field,
    required this.selected,
    required this.enabledColor,
    required this.enabledTextColor,
    required this.disabledColor,
    this.isPassword = false,
    this.ispasswordev = true,
    this.onTap,
    this.togglePassword,
  });

  bool get _isSelected => selected == field;
  Color get _color => _isSelected ? enabledTextColor : disabledColor;

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return FadeAnimationWidget(
      delay: 1,
      child: Container(
        width: we * 0.9,
        height: he * 0.082,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: secondaryColor, width: 2),
          color: _isSelected ? enabledColor : bgColor,
        ),
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: controller,
          onTap: onTap,
          obscureText: isPassword ? ispasswordev : false,
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: _color),
            suffixIcon: isPassword
                ? IconButton(
                    icon: ispasswordev
                        ? Icon(Icons.visibility_off, color: _color)
                        : Icon(Icons.visibility, color: _color),
                    onPressed: togglePassword,
                  )
                : null,
            hintText: hintText,
            hintStyle: TextStyle(color: _color),
          ),
          style: TextStyle(color: _color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
