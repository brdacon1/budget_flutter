import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/singup/presenter/strings/singup_pt_string.dart';

/// Rodapé "Já tem uma conta? Entre" da tela de cadastro.
///
/// Component `Stateless` puro — recebe apenas o callback de navegação para a
/// tela de login. Não acessa services nem o ViewModel.
class SingUpLoginLink extends StatelessWidget {
  final VoidCallback onLogin;

  const SingUpLoginLink({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          SingUpStrings.signUpLoginPrompt,
          style: GoogleFonts.heebo(
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        GestureDetector(
          onTap: onLogin,
          child: Text(
            SingUpStrings.signUpLoginAction,
            style: GoogleFonts.heebo(
              color: buttonColor.withOpacity(0.9),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
