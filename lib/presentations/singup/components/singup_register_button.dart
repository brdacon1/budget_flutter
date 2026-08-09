import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';

/// Botão "REGISTRAR" da tela de cadastro.
///
/// Component `Stateless` puro — recebe apenas um callback (`onPressed`).
/// Não acessa services nem o ViewModel.
class SingUpRegisterButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SingUpRegisterButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FadeAnimationWidget(
      delay: 1,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          "REGISTRAR",
          style: GoogleFonts.heebo(
            color: Colors.black,
            letterSpacing: 0.5,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
