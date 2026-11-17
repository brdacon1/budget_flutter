import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

class BudgetListStatusChip extends StatelessWidget {
  const BudgetListStatusChip({super.key, required this.status});

  final String? status;

  Color get _color {
    switch (status?.toUpperCase()) {
      case 'APROVADO':
        return statusApprovedColor;
      case 'REPROVADO':
        return statusRejectedColor;
      default:
        return statusPendingColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = status ?? '';
    final label =
        text.isEmpty
            ? ''
            : text[0].toUpperCase() + text.substring(1).toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
