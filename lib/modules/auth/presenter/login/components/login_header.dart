import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 55),
      child: Image.asset(
        'assets/login-initial-page.png',
        width: width * 0.45,
        height: height * 0.23,
        fit: BoxFit.contain,
      ),
    );
  }
}
