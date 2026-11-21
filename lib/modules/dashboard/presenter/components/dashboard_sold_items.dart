import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_section.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Produtos e serviços vendidos no mês: quantidade e valor.
class DashboardSoldItems extends StatelessWidget {
  const DashboardSoldItems({super.key, required this.summary});

  final DashboardMonthSummary summary;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: DashboardStrings.soldInMonth,
      children: [
        Text(
          DashboardStrings.soldHint,
          style: const TextStyle(color: mutedTextColor, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        _row(
          context,
          Icons.inventory_2_outlined,
          productPillColor,
          ItemCategory.products.label,
          summary.products,
        ),
        _row(
          context,
          Icons.handyman_outlined,
          cartAccentColor,
          ItemCategory.services.label,
          summary.services,
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
    DashboardSoldTotals item,
  ) {
    final text = Theme.of(context).textTheme.bodyLarge!;
    return Container(
      margin: const EdgeInsets.only(top: defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: primaryColor.withValues(alpha: 0.15),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(defaultPadding)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DashboardStrings.quantity(item.quantity),
                  style: text.copyWith(color: mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            getIt<ConvertCoinRepository>().convertFromDouble(item.total),
            style: text,
          ),
        ],
      ),
    );
  }
}
