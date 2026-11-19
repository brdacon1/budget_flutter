import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Botão de login com Apple, mesmo estilo do [LoginGoogleButton].
/// Exibido só em dispositivos Apple.
class LoginAppleButton extends StatelessWidget {
  const LoginAppleButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

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
            const Icon(Icons.apple, color: Colors.black, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  LoginStrings.loginWithApple,
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
