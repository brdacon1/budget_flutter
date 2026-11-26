import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/shared/common/constants/colors.dart';

import 'budget_list_items_category_tag.dart';

/// Card de item do orçamento.
///
/// Todas as informações ficam visíveis (sem expandir). Arrastar para a
/// esquerda revela o botão Remover; tocar nele chama [onToggleSelect], que
/// põe o item no buffer de remoção e liga o modo de seleção
/// ([selectionMode]). Nesse modo não há swipe: o toque no card também chama
/// [onToggleSelect] (decidido pela View) e o card selecionado ganha destaque.
class BudgetListItemsCard extends StatefulWidget {
  const BudgetListItemsCard({
    super.key,
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.moneyConvert,
    required this.onTap,
    required this.onToggleSelect,
  });

  final ItemsBudget item;
  final bool selected;
  final bool selectionMode;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;

  @override
  State<BudgetListItemsCard> createState() => _BudgetListItemsCardState();
}

class _BudgetListItemsCardState extends State<BudgetListItemsCard>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 90;
  static const double _radius = 18;
  static const Color _productColor = Color(0xFFC77DFF);
  static const Color _serviceColor = Color(0xFF2ED3A6);
  static const double _descriptionFontSize = 15;
  static const double _descriptionLineHeight = 1.25;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  bool get _open => _ctrl.value > 0.5;

  @override
  void didUpdateWidget(covariant BudgetListItemsCard old) {
    super.didUpdateWidget(old);
    if (widget.selectionMode && _ctrl.value > 0) _ctrl.value = 0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (widget.selectionMode) return;
    _ctrl.value = (_ctrl.value - d.primaryDelta! / _actionWidth).clamp(
      0.0,
      1.0,
    );
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final open = v < -300 || (v <= 300 && _ctrl.value > 0.5);
    _ctrl.animateTo(open ? 1 : 0, curve: Curves.easeOut);
  }

  void _close() => _ctrl.animateTo(0, curve: Curves.easeOut);

  void _onRemoveTap() {
    _ctrl.value = 0;
    widget.onToggleSelect();
  }

  String _qty(double? q) {
    final v = q ?? 0;
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final category = ItemCategory.fromValue(item.category);
    final isService = category == ItemCategory.services;
    final accent = isService ? _serviceColor : _productColor;
    final measure = (item.measure ?? '').trim();
    final selected = widget.selected;

    // Altura FIXA (não depende do texto): todos os cards ficam iguais.
    final scale = MediaQuery.textScalerOf(context).scale;
    final descriptionHeight =
        scale(_descriptionFontSize * _descriptionLineHeight) * 2;
    final cardHeight = 26 + descriptionHeight + 4 + scale(16);

    final account =
        '${_qty(item.quantity)}${measure.isEmpty ? '' : ' $measure'}'
        ' × ${widget.moneyConvert.convertFromDouble(item.price ?? 0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        height: cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Stack(
            children: [
              // Ação revelada atrás do card.
              Positioned.fill(
                child: Container(
                  color: statusRejectedColor,
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _actionWidth,
                    child: InkWell(
                      onTap: _onRemoveTap,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: whiteColor,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Remover',
                            style: GoogleFonts.heebo(
                              color: whiteColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _ctrl,
                builder:
                    (context, child) => Transform.translate(
                      offset: Offset(-_ctrl.value * _actionWidth, 0),
                      child: child,
                    ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onTap: () => _open ? _close() : widget.onTap(),
                  child: Container(
                    height: cardHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? Color.alphaBlend(
                                buttonColor.withValues(alpha: 0.08),
                                secondaryColor,
                              )
                              : secondaryColor,
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(
                        color: selected ? buttonColor : cardBorderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildIcon(isService, accent, selected),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: descriptionHeight,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item.description ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.heebo(
                                      color: whiteColor,
                                      fontSize: _descriptionFontSize,
                                      fontWeight: FontWeight.w600,
                                      height: _descriptionLineHeight,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                account,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.heebo(
                                  color: mutedTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Total sempre visível: coluna não é cortada nem
                        // quebra linha; quem cede espaço é a descrição.
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.moneyConvert.convertFromDouble(
                                item.total ?? 0,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              style: GoogleFonts.heebo(
                                color: whiteColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            BudgetListItemsCategoryTag(
                              label: isService ? 'Serviço' : 'Produto',
                              color: accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ícone grande da categoria; vira check quando o item está selecionado.
  Widget _buildIcon(bool isService, Color accent, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? buttonColor : accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        selected
            ? Icons.check_rounded
            : (isService ? Icons.handyman_outlined : Icons.view_in_ar_outlined),
        color: selected ? bgColor : accent,
        size: 24,
      ),
    );
  }
}
