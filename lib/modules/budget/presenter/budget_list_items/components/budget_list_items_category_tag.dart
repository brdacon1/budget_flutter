import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tag em pílula da categoria (Produto/Serviço) do card de item.
class BudgetListItemsCategoryTag extends StatelessWidget {
  const BudgetListItemsCategoryTag({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: GoogleFonts.heebo(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
