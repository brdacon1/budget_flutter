import 'package:flutter/material.dart';
import 'package:oflite/shared/common/enums/singup_field_enum.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Campo de texto estilizado reutilizável do modal de cadastro.
///
/// Segue o **padrão visual dos bottom modals** do app (ver
/// `change_password_bottom_modal_widget.dart` / `text_input_bottom_modal_widget.dart`):
/// - fundo **branco**;
/// - borda cinza `0xFF9E9E9E`;
/// - texto, ícone e hint em [AppBottomModal.grayColor] (cinza máximo);
/// - toggle de visibilidade para o campo de senha.
///
/// Component `Stateless` puro — recebe dados (`controller`, `hintText`, `icon`,
/// `field`, `isPassword`) e callbacks (`onTap`, `togglePassword`). Não acessa
/// services nem o ViewModel. `field` continua sendo recebido para que o VM
/// saiba qual campo está focado (limpar estado de erro ao interagir).
class SingUpField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final SingUpFieldType field;
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
    this.isPassword = false,
    this.ispasswordev = true,
    this.onTap,
    this.togglePassword,
  });

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
          onTap: onTap,
          obscureText: isPassword ? ispasswordev : false,
          keyboardType:
              field == SingUpFieldType.email
                  ? TextInputType.emailAddress
                  : TextInputType.text,
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: AppBottomModal.grayColor),
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        ispasswordev ? Icons.visibility_off : Icons.visibility,
                        color: AppBottomModal.grayColor,
                      ),
                      onPressed: togglePassword,
                    )
                    : null,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          style: TextStyle(
            color: AppBottomModal.grayColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
