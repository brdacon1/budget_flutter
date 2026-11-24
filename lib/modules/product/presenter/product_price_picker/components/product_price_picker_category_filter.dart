import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Filtro por categoria do picker: Todos / Produtos / Serviços, no mesmo
/// padrão dos filtros das outras telas. `null` em [selected] = Todos.
class ProductPricePickerCategoryFilter extends StatelessWidget {
  const ProductPricePickerCategoryFilter({
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
      padding: const EdgeInsets.symmetric(horizontal: 17),
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
