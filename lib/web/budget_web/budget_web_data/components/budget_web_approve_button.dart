import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';

/// Botão "Aprovar orçamento" da aba "Meus dados" — reflete o **status atual**
/// do orçamento através da cor e do label:
///
/// - `APROVADO` → verde (`Colors.green`) + "Orçamento aprovado"
/// - `REPROVADO` → vermelho (`Colors.red`) + "Orçamento reprovado"
/// - demais (`PENDENTE`/`FINALIZADO`/nulo) → cor padrão (`buttonColor`) +
///   "Aprovar orçamento"
///
/// Ao tocar, abre o modal de aprovação (callback `onPressed`). Reutiliza os
/// mesmos valores de status do app mobile — nenhuma regra paralela.
///
/// Component **Stateless** puro.
class BudgetWebApproveButton extends StatelessWidget {
  const BudgetWebApproveButton({
    super.key,
    required this.status,
    required this.onPressed,
  });

  final String? status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final normalized = (status ?? '').toUpperCase();
    final Color color;
    final String label;
    final IconData icon;
    final Color textColor;
    if (normalized == 'APROVADO') {
      color = Colors.green;
      textColor = Colors.white;
      icon = Icons.check_circle;
      label = BudgetWebStrings.approveButtonApproved;
    } else if (normalized == 'REPROVADO') {
      color = Colors.red;
      textColor = Colors.white;
      icon = Icons.cancel;
      label = BudgetWebStrings.approveButtonRejected;
    } else {
      color = buttonColor;
      textColor = bgColor;
      icon = Icons.task_alt;
      label = BudgetWebStrings.approveButton;
    }

    return SizedBox(
      width: we * 0.7,
      height: 52,
      child: FloatingActionButton.extended(
        heroTag: 'approve',
        backgroundColor: color,
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.heebo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
