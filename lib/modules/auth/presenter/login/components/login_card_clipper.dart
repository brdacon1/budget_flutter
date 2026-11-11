import 'package:flutter/material.dart';

/// Clipper da borda superior do card de login.
///
/// Formato em "S" / bigode: desce à esquerda, sobe no centro e
/// desce novamente à direita.
class LoginCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final h = 50.0;

    path.moveTo(0, 0);

    path.cubicTo(
      size.width * 0.33,
      h * 1.4,      // desce à esquerda
      size.width * 0.66,
      -h * 1.2,     // sobe no centro
      size.width,
      h * 0.9,      // desce à direita
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
