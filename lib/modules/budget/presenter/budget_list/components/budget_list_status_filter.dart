import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Chips de filtro por status da lista de orçamentos (só assinantes).
class BudgetListStatusFilter extends StatelessWidget {
  const BudgetListStatusFilter({
    super.key,
    required this.status,
    required this.onStatus,
  });

  final BudgetStatus? status;
  final ValueChanged<BudgetStatus?> onStatus;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          _chip(BudgetStrings.filterAllStatus, null),
          for (final s in BudgetStatus.values)
            _chip(BudgetStrings.statusLabel(s.value), s),
        ],
      ),
    );
  }

  Widget _chip(String label, BudgetStatus? value) {
    final selected = status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onStatus(value),
        backgroundColor: secondaryColor,
        selectedColor: buttonColor,
        side: BorderSide(color: selected ? buttonColor : cardBorderColor),
        labelStyle: TextStyle(
          color: selected ? blackColor : whiteColor,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
