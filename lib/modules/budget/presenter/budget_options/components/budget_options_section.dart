import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/presenter/budget_options/budget_options_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_options/components/budget_options_card.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Título de seção + cards das suas opções.
class BudgetOptionsSection extends StatelessWidget {
  final String title;
  final List<BudgetOption> options;
  final ValueChanged<BudgetOption> onOptionTap;

  const BudgetOptionsSection({
    super.key,
    required this.title,
    required this.options,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: mutedTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        for (final option in options)
          BudgetOptionsCard(option: option, onTap: () => onOptionTap(option)),
      ],
    );
  }
}
