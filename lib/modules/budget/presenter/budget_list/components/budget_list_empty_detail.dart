import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Painel de detalhe sem orçamento aberto (tela larga).
class BudgetListEmptyDetail extends StatelessWidget {
  const BudgetListEmptyDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_outlined,
              color: emptyStateIconColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              BudgetStrings.selectBudgetHint,
              style: GoogleFonts.heebo(
                color: loadingIndicatorColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
