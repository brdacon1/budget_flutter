import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/shared/common/constants/constants.dart';

/// Row com label "Lembrar de mim" e Switch.
class LoginRememberMeSwitch extends StatelessWidget {
  const LoginRememberMeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          LoginStrings.loginRememberMe,
          style: GoogleFonts.heebo(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: buttonColor,
          activeTrackColor: buttonColor.withValues(alpha: 0.5),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
