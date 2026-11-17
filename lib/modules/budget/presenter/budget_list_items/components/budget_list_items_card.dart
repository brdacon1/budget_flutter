import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card de item do orçamento.
///
/// Todas as informações ficam visíveis (sem expandir): descrição, categoria,
/// quantidade × preço e total. A seleção para remoção é feita direto na tela
/// pelo check circular (mesmo padrão da lista de preços).
class BudgetListItemsCard extends StatelessWidget {
  const BudgetListItemsCard({
    super.key,
    required this.item,
    required this.selected,
    required this.moneyConvert,
    required this.onToggleSelect,
  });

  final ItemsBudget item;
  final bool selected;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onToggleSelect;

  String _qty(double? q) {
    final v = q ?? 0;
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final category = ItemCategory.fromValue(item.category);
    final isService = category == ItemCategory.services;
    final measure = (item.measure ?? '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? buttonColor.withValues(alpha: 0.08) : secondaryColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggleSelect,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? buttonColor : transparentColor,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: bgColor,
                  child: Icon(
                    isService
                        ? Icons.handyman_outlined
                        : Icons.inventory_2_outlined,
                    color: buttonColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.heebo(
                          color: whiteColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_qty(item.quantity)}${measure.isEmpty ? '' : ' $measure'}'
                        ' × ${moneyConvert.convertFromDouble(item.price ?? 0)}',
                        style: GoogleFonts.heebo(
                            color: mutedTextColor, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category?.label ?? (item.category ?? ''),
                              style: GoogleFonts.heebo(
                                  color: mutedTextColor, fontSize: 11),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            moneyConvert.convertFromDouble(item.total ?? 0),
                            style: GoogleFonts.heebo(
                              color: whiteColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _SelectCircle(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectCircle extends StatelessWidget {
  const _SelectCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? buttonColor : transparentColor,
        border: Border.all(
          color: selected ? buttonColor : mutedTextColor,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: bgColor)
          : null,
    );
  }
}
