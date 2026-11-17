import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/budget_creator_view_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'budget_creator_info_section.dart';

/// Identificação imutável do orçamento no modo editar (§17.5):
/// nº e data como texto informativo, nunca como campo desabilitado.
class BudgetCreatorSummaryCard extends StatelessWidget {
  const BudgetCreatorSummaryCard({super.key, required this.viewModel});

  final BudgetCreatorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item;
    final status = item.status ?? '';
    final color = BudgetCreatorInfoSection.colorFor(status);
    final total = NumberFormat.simpleCurrency(locale: 'pt_BR')
        .format(item.totalValue ?? 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sheetHandleColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orçamento',
                    style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  '#${item.id ?? ''}',
                  style: GoogleFonts.heebo(
                      color: whiteColor, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: mutedTextColor, size: 13),
                  const SizedBox(width: 4),
                  Text('Criado em ${item.data ?? '-'}',
                      style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 12)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    BudgetCreatorInfoSection.labelFor(status),
                    style: GoogleFonts.heebo(
                        color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 8),
              Text(total,
                  style: GoogleFonts.heebo(
                      color: whiteColor, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
