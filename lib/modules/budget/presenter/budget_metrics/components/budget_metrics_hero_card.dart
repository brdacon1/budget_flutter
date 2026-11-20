import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_card_box.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Total do orçamento, valor a receber e anel de % recebido.
class BudgetMetricsHeroCard extends StatelessWidget {
  const BudgetMetricsHeroCard({
    super.key,
    required this.total,
    required this.toReceive,
    required this.ratio,
  });

  final String total;
  final String toReceive;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final muted = GoogleFonts.heebo(color: mutedTextColor, fontSize: 13);
    final percent = (ratio * 100).round();
    return BudgetMetricsCardBox(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(BudgetStrings.metricsBudgetTotal, style: muted),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    total,
                    style: GoogleFonts.heebo(
                      color: whiteColor,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(BudgetStrings.metricsToReceive, style: muted),
                Text(
                  toReceive,
                  style: GoogleFonts.heebo(
                    color: statusPendingColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: bgColor,
                  color: statusApprovedColor,
                ),
                Center(
                  child: Text(
                    BudgetStrings.metricsReceivedPercent(percent),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.heebo(
                      color: whiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
