import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/strings/auth_strings.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeAnimationWidget(
          delay: 0.8,
          child: Image.asset(
            'assets/login-initial-page.png',
            width: width * 0.5,
            height: height * 0.25,
          ),
        ),
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            margin: const EdgeInsets.only(right: 240.0),
            child: Text(
              AuthStrings.loginTitle,
              style: GoogleFonts.heebo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 35,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
