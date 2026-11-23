import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_list/components/card/budget_list_status_chip.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/common/constants/colors.dart';

class BudgetListCard extends StatelessWidget {
  const BudgetListCard({
    super.key,
    required this.item,
    required this.selected,
    required this.moneyConvert,
    required this.onTap,
    required this.onMore,
  });

  final CustomerInfo item;
  final bool selected;
  final ConvertCoinRepository moneyConvert;

  /// `null` = card sem ações (sem toque nem menu).
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final name = item.customerName ?? '';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? buttonColor : cardBorderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onMore,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 4, 13),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: buttonColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child:
                      selected
                          ? const Icon(Icons.check_rounded, color: buttonColor)
                          : Text(
                            initial,
                            style: const TextStyle(
                              color: buttonColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${BudgetStrings.budgetNumber} ${item.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: whiteColor, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.data ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      moneyConvert.convertFromDouble(item.totalValue ?? 0),
                      style: const TextStyle(
                        color: whiteColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    BudgetListStatusChip(status: item.status),
                  ],
                ),
                if (onMore != null)
                  IconButton(
                    onPressed: onMore,
                    icon: const Icon(Icons.more_vert, color: mutedTextColor),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
