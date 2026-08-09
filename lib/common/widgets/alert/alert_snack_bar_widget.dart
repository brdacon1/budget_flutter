import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/enums/alert_type_enum.dart';

/// Snackbar padrão do app para notificações de sucesso/erro/aviso.
///
/// Substitui os antigos `AwesomeDialog` de alerta. Mantém o padrão de cores
/// (verde = sucesso, vermelho = erro, laranja = aviso) e exibe `title` +
/// `message`. Todos os textos são `Colors.grey[900]` (cinza máximo) sobre o
/// fundo colorido, conforme padrão visual definido para os alertas.
class AlertSnackBar {
  AlertSnackBar._();

  static void show(
    BuildContext context, {
    required AlertType type,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: type.background,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(type), color: Colors.grey[100], size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.heebo(
                        color: Colors.grey[100],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: GoogleFonts.heebo(
                        color: Colors.grey[200],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  static IconData _iconFor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.error:
        return Icons.error_outline;
    }
  }
}
