import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/strings/auth_strings.dart';

/// Rodapé do login com o atalho de **Política de privacidade**.
///
/// Antes abrigava o cadastro, que agora é um botão em destaque logo abaixo do
/// "Entrar" (ver [LoginView]). O rodapé fica dentro de um [SafeArea] para
/// garantir que o botão não seja cortado pela área de gestos/insets do
/// dispositivo.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key, required this.onPrivacyPolicy});

  /// Callback disparado ao tocar em "Política de privacidade".
  final VoidCallback onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: BottomAppBar(
        color: bgColor,
        elevation: 0,
        child: SizedBox(
          height: 48.0,
          child: Center(
            child: GestureDetector(
              onTap: onPrivacyPolicy,
              behavior: HitTestBehavior.opaque,
              child: Text(
                AuthStrings.loginPrivacyPolicy,
                style: GoogleFonts.heebo(
                  color: buttonColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
