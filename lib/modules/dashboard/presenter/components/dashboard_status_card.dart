import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_status_style.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Bloco compacto de um status: nome · qtd, valor orçado e recebido.
class DashboardStatusCard extends StatelessWidget {
  const DashboardStatusCard({
    super.key,
    required this.status,
    required this.item,
  });

  final DashboardStatus status;
  final DashboardStatusSummary item;

  @override
  Widget build(BuildContext context) {
    final money = getIt<ConvertCoinRepository>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: status.color, width: 3)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${status.label} · ${item.count}',
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money.convertFromDouble(item.budgeted),
              style: const TextStyle(
                color: creamColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${DashboardStrings.received}: '
            '${money.convertFromDouble(item.received)}',
            style: const TextStyle(color: mutedTextColor, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
