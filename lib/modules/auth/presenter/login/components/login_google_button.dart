import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Botão de login com Google estilizado para o card de login.
class LoginGoogleButton extends StatelessWidget {
  const LoginGoogleButton({super.key, required this.onPressed, this.label});

  final VoidCallback onPressed;

  /// Texto do botão; padrão = "Login com ...".
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: whiteColor,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/png/google_logo.png', height: 24, width: 24),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label ?? LoginStrings.loginWithGoogle,
                  style: GoogleFonts.heebo(
                    color: bgColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
