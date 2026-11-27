import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Recibos gerados no mês: quantidade e valor total.
class HomeReceiptsCard extends StatelessWidget {
  const HomeReceiptsCard({super.key, required this.data});

  final DashboardReceiptsSummary data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: cardBorderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: buttonColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  HomeStrings.receiptsIssued,
                  style: const TextStyle(color: mutedTextColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.count}',
                  style: const TextStyle(
                    color: whiteColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              getIt<ConvertCoinRepository>().convertFromDouble(data.issued),
              style: const TextStyle(
                color: buttonColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
