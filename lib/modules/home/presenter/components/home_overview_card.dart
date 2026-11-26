import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_status_style.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Um status do mês: rótulo, quantidade e valor orçado.
class HomeOverviewCard extends StatelessWidget {
  const HomeOverviewCard({super.key, required this.status, required this.data});

  final DashboardStatus status;
  final DashboardStatusSummary data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status.label,
                style: const TextStyle(color: mutedTextColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${data.count}',
            style: const TextStyle(
              color: whiteColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              getIt<ConvertCoinRepository>().convertFromDouble(data.budgeted),
              style: TextStyle(
                color: status.color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
