import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/login-initial-page.png',
          width: width * 0.5,
          height: height * 0.25,
        ),
        Container(
          margin: const EdgeInsets.only(right: 240.0),
          child: Text(
            LoginStrings.loginTitle,
            style: GoogleFonts.heebo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 35,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}
