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

  Widget _line(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.heebo(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(value, style: GoogleFonts.heebo(color: whiteColor, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = GoogleFonts.heebo(color: mutedTextColor, fontSize: 12);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: secondaryColor,
        border: Border(top: BorderSide(color: sheetHandleColor)),
      ),
      // Aberta fora da tab bar (ex.: pelo chat), a barra fica colada na
      // borda inferior; o SafeArea afasta o conteúdo do home indicator.
      // Dentro da tab bar o padding inferior já foi consumido (fica 0).
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _line('Produtos', products, productPillColor),
                  const SizedBox(height: 4),
                  _line('Serviços', services, cartAccentColor),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total (produtos + serviços)', style: muted),
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
      ),
    );
  }
}
