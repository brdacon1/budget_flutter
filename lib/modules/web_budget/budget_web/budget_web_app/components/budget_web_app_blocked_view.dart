import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/constants.dart';

/// Tela de bloqueio do fluxo Web: link inválido, token expirado ou orçamento
/// inexistente. Não exibe nenhum dado do orçamento.
class BudgetWebAppBlockedView extends StatelessWidget {
  const BudgetWebAppBlockedView({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: secondaryColor,
                child: Icon(Icons.lock_outline, color: buttonColor, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.heebo(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.heebo(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
