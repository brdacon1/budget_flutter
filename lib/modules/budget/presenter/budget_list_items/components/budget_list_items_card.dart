import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card de item do orçamento.
///
/// Todas as informações ficam visíveis (sem expandir): descrição, categoria,
/// quantidade × preço e total. Tocar no card abre os detalhes do item
/// ([onTap]); a seleção para remoção é feita só pelo check circular
/// ([onToggleSelect]).
class BudgetListItemsCard extends StatelessWidget {
  const BudgetListItemsCard({
    super.key,
    required this.item,
    required this.selected,
    required this.moneyConvert,
    required this.onTap,
    required this.onToggleSelect,
  });

  final ItemsBudget item;
  final bool selected;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;

  static const double _descriptionFontSize = 14;
  static const double _descriptionLineHeight = 1.25;

  String _qty(double? q) {
    final v = q ?? 0;
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final category = ItemCategory.fromValue(item.category);
    final isService = category == ItemCategory.services;
    final measure = (item.measure ?? '').trim();

    // Altura FIXA (não depende do texto): cada bloco tem altura reservada e
    // o texto que não couber é cortado com reticências. Todos os cards ficam
    // exatamente do mesmo tamanho.
    final scale = MediaQuery.textScalerOf(context).scale;
    final descriptionHeight =
        scale(_descriptionFontSize * _descriptionLineHeight) * 2;
    final quantityHeight = scale(18);
    final footerHeight = scale(24);
    final cardHeight =
        // 28 = padding vertical; 2 = borda de 1 px do card.
        30 + descriptionHeight + 4 + quantityHeight + 6 + footerHeight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? buttonColor.withValues(alpha: 0.08) : secondaryColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: cardHeight,
            padding: const EdgeInsets.fromLTRB(14, 14, 3, 14),
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
                      // Altura fixa de 2 linhas: todos os cards ficam do mesmo
                      // tamanho, com a descrição curta ou longa.
                      SizedBox(
                        height: descriptionHeight,
                        child: Text(
                          item.description ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.heebo(
                            color: whiteColor,
                            fontSize: _descriptionFontSize,
                            fontWeight: FontWeight.bold,
                            height: _descriptionLineHeight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: quantityHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${_qty(item.quantity)}${measure.isEmpty ? '' : ' $measure'}'
                            ' × ${moneyConvert.convertFromDouble(item.price ?? 0)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.heebo(
                              color: mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: footerHeight,
                        child: Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isService
                                          ? cartAccentColor
                                          : productPillColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  category?.label ?? (item.category ?? ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '= ${moneyConvert.convertFromDouble(item.total ?? 0)}',
                                  maxLines: 1,
                                  style: GoogleFonts.heebo(
                                    color: priceTextColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 1),
                // Área de toque de 48px só para o check (26 + 2 × 11).
                InkResponse(
                  onTap: onToggleSelect,
                  radius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: _SelectCircle(selected: selected),
                  ),
                ),
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
      child:
          selected ? const Icon(Icons.check, size: 16, color: bgColor) : null,
    );
  }
}
