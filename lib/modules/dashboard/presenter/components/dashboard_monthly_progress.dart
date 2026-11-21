import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_section.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_status_style.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Valor orçado no mês por status: barra com brilho + valor + % do total.
class DashboardMonthlyProgress extends StatelessWidget {
  const DashboardMonthlyProgress({super.key, required this.summary});

  final DashboardMonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final money = getIt<ConvertCoinRepository>();
    final total = DashboardStatus.values.fold<double>(
      0,
      (s, e) => s + summary.of(e).budgeted,
    );

    return DashboardSection(
      title: DashboardStrings.monthlyProgress,
      children: [
        Text(
          '${DashboardStrings.total}: ${money.convertFromDouble(total)}',
          style: const TextStyle(
            color: creamColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        for (final s in DashboardStatus.values)
          _bar(s, summary.of(s).budgeted, total, money),
      ],
    );
  }

  Widget _bar(
    DashboardStatus s,
    double value,
    double total,
    ConvertCoinRepository money,
  ) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(top: defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(s.icon, color: s.color, size: 16),
              const SizedBox(width: 8),
              Text(
                s.label,
                style: TextStyle(
                  color: s.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                money.convertFromDouble(value),
                style: const TextStyle(
                  color: creamColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${(ratio * 100).round()}%',
                  style: const TextStyle(color: mutedTextColor, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: cardBorderColor,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder:
                  (_, v, __) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [s.color.withValues(alpha: 0.6), s.color],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: s.color.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
