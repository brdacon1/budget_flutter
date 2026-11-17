import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/budget_creator_view_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/form/app_form_section_card.dart';

/// Status em chips: poucas opções fixas → um toque (Lei de Hick, §17.2).
class BudgetCreatorInfoSection extends StatelessWidget {
  const BudgetCreatorInfoSection({super.key, required this.viewModel});

  final BudgetCreatorViewModel viewModel;

  static Color colorFor(String status) {
    switch (status) {
      case 'APROVADO':
      case 'FINALIZADO':
        return statusApprovedColor;
      case 'REPROVADO':
        return statusRejectedColor;
      default:
        return statusPendingColor;
    }
  }

  static String labelFor(String status) =>
      status.isEmpty ? '' : status[0] + status.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return AppFormSectionCard(
      icon: Icons.flag_outlined,
      title: 'Status',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BudgetCreatorViewModel.statusOptions.map((status) {
            final selected = viewModel.statusController.text == status;
            final color = colorFor(status);
            return ChoiceChip(
              label: Text(labelFor(status)),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => viewModel.setStatus(status),
              backgroundColor: bgColor,
              selectedColor: color.withValues(alpha: 0.15),
              side: BorderSide(color: selected ? color : sheetHandleColor),
              shape: const StadiumBorder(),
              labelStyle: GoogleFonts.heebo(
                color: selected ? color : whiteColor,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
