import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_card_box.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Quanto do valor recebido está comprovado e quanto falta comprovar.
class BudgetMetricsProofCoverageCard extends StatelessWidget {
  const BudgetMetricsProofCoverageCard({
    super.key,
    required this.ratio,
    required this.unproven,
    required this.hasUnproven,
  });

  final double ratio;
  final String unproven;
  final bool hasUnproven;

  @override
  Widget build(BuildContext context) {
    final percent = (ratio * 100).round();
    return BudgetMetricsCardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: buttonColor, size: 18),
              const SizedBox(width: 6),
              Text(
                BudgetStrings.metricsProofCoverage,
                style: GoogleFonts.heebo(
                  color: whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: bgColor,
              color: statusApprovedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            BudgetStrings.metricsProofCoveragePercent(percent),
            style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  BudgetStrings.metricsUnproven,
                  style: GoogleFonts.heebo(color: whiteColor, fontSize: 14),
                ),
              ),
              Text(
                unproven,
                style: GoogleFonts.heebo(
                  color: hasUnproven ? statusPendingColor : statusApprovedColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
