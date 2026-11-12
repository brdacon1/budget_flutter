import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/shared/common/constants/constants.dart';

/// Link de **Política de privacidade** usado dentro do card de login.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key, required this.onPrivacyPolicy});

  /// Callback disparado ao tocar em "Política de privacidade".
  final VoidCallback onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPrivacyPolicy,
      behavior: HitTestBehavior.opaque,
      child: Text(
        LoginStrings.loginPrivacyPolicy,
        style: GoogleFonts.heebo(
          color: buttonColor.withValues(alpha: 0.9),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          fontSize: 16,
        ),
      ),
    );
  }
}
