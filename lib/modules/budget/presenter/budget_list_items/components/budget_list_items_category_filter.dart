import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Chips de filtro por categoria dos itens do orçamento (Todos / Produtos /
/// Serviços), no mesmo visual do filtro de status da lista de orçamentos.
/// `null` em [selected] = Todos.
class BudgetListItemsCategoryFilter extends StatelessWidget {
  const BudgetListItemsCategoryFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ItemCategory? selected;
  final ValueChanged<ItemCategory?> onChanged;

  Widget _chip(String label, ItemCategory? value) {
    final active = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        onSelected: (_) => onChanged(value),
        backgroundColor: secondaryColor,
        selectedColor: buttonColor,
        side: BorderSide(color: active ? buttonColor : cardBorderColor),
        labelStyle: TextStyle(
          color: active ? blackColor : whiteColor,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          _chip(ProductPtString.filterAll, null),
          _chip(ItemCategory.products.label, ItemCategory.products),
          _chip(ItemCategory.services.label, ItemCategory.services),
        ],
      ),
    );
  }
}
