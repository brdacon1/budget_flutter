import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_card_box.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card pequeno da grade: ícone, título e valor.
class BudgetMetricsTile extends StatelessWidget {
  const BudgetMetricsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.count,
  });

  final IconData icon;
  final String title;
  final String value;

  /// Quando informado, mostra a quantidade abaixo do valor.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return BudgetMetricsCardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: buttonColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 13),
                ),
              ),
            ],
          ),
          if (count == null)
            _line(value, 22, whiteColor)
          else ...[
            _line(value, 18, whiteColor),
            _line('$count', 14, whiteColor),
          ],
        ],
      ),
    );
  }

  Widget _line(String text, double size, Color color) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: GoogleFonts.heebo(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
