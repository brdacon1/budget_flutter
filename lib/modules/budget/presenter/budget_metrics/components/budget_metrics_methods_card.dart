import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/domain/entity/budget_metrics.dart';
import 'package:oflite/modules/budget/presenter/budget_metrics/components/budget_metrics_card_box.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/receipt/domain/entity/payment_method.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Total de recibos + barra segmentada e linhas por forma de pagamento.
class BudgetMetricsMethodsCard extends StatelessWidget {
  const BudgetMetricsMethodsCard({
    super.key,
    required this.metrics,
    required this.money,
  });

  final BudgetMetrics metrics;
  final String Function(double) money;

  static Color _color(PaymentMethod? m) => switch (m) {
    PaymentMethod.cash => statusApprovedColor,
    PaymentMethod.pix => buttonColor,
    PaymentMethod.credit => primaryColor,
    PaymentMethod.debit => statusPendingColor,
    null => mutedTextColor,
  };

  @override
  Widget build(BuildContext context) {
    final total = metrics.receiptsTotal;
    final rows = <(PaymentMethod?, String, double)>[
      for (final m in PaymentMethod.values)
        (m, m.label, metrics.byMethod[m] ?? 0),
      if ((metrics.byMethod[null] ?? 0) > 0)
        (null, BudgetStrings.metricsOthers, metrics.byMethod[null]!),
    ];
    final muted = GoogleFonts.heebo(color: mutedTextColor, fontSize: 13);

    return BudgetMetricsCardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: buttonColor, size: 18),
              const SizedBox(width: 6),
              Text(
                BudgetStrings.metricsReceived,
                style: GoogleFonts.heebo(
                  color: whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            money(total),
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            BudgetStrings.metricsReceiptsCount(metrics.receiptsCount),
            style: muted,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child:
                  total <= 0
                      ? Container(color: bgColor)
                      : Row(
                        children: [
                          for (final r in rows)
                            if (r.$3 > 0)
                              Expanded(
                                flex: (r.$3 / total * 1000).round().clamp(
                                  1,
                                  1000,
                                ),
                                child: Container(color: _color(r.$1)),
                              ),
                        ],
                      ),
            ),
          ),
          const SizedBox(height: 12),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _color(r.$1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: GoogleFonts.heebo(color: whiteColor, fontSize: 14),
                    ),
                  ),
                  Text(
                    money(r.$3),
                    style: GoogleFonts.heebo(
                      color: whiteColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      total > 0 ? '${(r.$3 / total * 100).round()}%' : '0%',
                      textAlign: TextAlign.end,
                      style: muted,
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
