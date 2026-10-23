import 'package:flutter/material.dart';

/// Tipo de alerta exibido via snackbar.
///
/// Cada tipo carrega a sua cor de fundo, mantendo o padrão visual anterior
/// (verde = sucesso, vermelho = erro, laranja = aviso) agora como snackbar.
enum AlertType {
  success,
  warning,
  error,
}

/// Extensão que resolve a cor de fundo do snackbar para cada [AlertType].
extension AlertTypeColor on AlertType {
  Color get background {
    switch (this) {
      case AlertType.success:
        return const Color(0xFF1B5E20); // greenColor
      case AlertType.warning:
        return const Color(0xFFE65100); // laranja
      case AlertType.error:
        return const Color(0xFFB71C1C); // redColor
    }
  }
}
