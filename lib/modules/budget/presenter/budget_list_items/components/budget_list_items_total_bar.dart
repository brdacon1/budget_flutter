import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Barra de totais fixa acima da tab bar: total em destaque + detalhamento.
class BudgetListItemsTotalBar extends StatelessWidget {
  const BudgetListItemsTotalBar({
    super.key,
    required this.total,
    required this.products,
    required this.services,
  });

  /// Valores já formatados em moeda.
  final String total;
  final String products;
  final String services;

  @override
  Widget build(BuildContext context) {
    final muted = GoogleFonts.heebo(color: mutedTextColor, fontSize: 12);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: secondaryColor,
        border: Border(top: BorderSide(color: sheetHandleColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Produtos  $products', style: muted),
                const SizedBox(height: 2),
                Text('Serviços  $services', style: muted),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total', style: muted),
              Text(
                total,
                style: GoogleFonts.heebo(
                  color: buttonColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
