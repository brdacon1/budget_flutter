import 'package:flutter/material.dart';

class StatusConfig {
  final Color color;
  final IconData icon;
  final Color bgLight;

  StatusConfig({
    required this.color,
    required this.icon,
    required this.bgLight,
  });
}

class GetBudgetStatusColor {
  static StatusConfig get(String status) {
    switch (status.toUpperCase()) {
      case 'APROVADO':
        return StatusConfig(
          color: const Color(0xFF2E7D32),
          icon: Icons.check,
          bgLight: const Color(0xFFE8F5E9),
        );
      case 'REPROVADO':
        return StatusConfig(
          color: Colors.red,
          icon: Icons.close_sharp,
          bgLight: Colors.red.withOpacity(0.1),
        );
      case 'PENDENTE':
        return StatusConfig(
          color: Colors.amber[800]!,
          icon: Icons.pending_outlined,
          bgLight: Colors.amber.withOpacity(0.1),
        );
      case 'FINALIZADO':
      default:
        return StatusConfig(
          color: Colors.grey.shade700,
          icon: Icons.circle,
          bgLight: Colors.grey.withOpacity(0.1),
        );
    }
  }
}