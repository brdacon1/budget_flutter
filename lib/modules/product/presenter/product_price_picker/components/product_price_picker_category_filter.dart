import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Filtro por categoria do picker: Todos / Produtos / Serviços.
/// `null` em [selected] = Todos.
class ProductPricePickerCategoryFilter extends StatelessWidget {
  const ProductPricePickerCategoryFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ItemCategory? selected;
  final ValueChanged<ItemCategory?> onChanged;

  Widget _chip(String label, ItemCategory? value, Color color) {
    final active = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        onSelected: (_) => onChanged(value),
        labelStyle: GoogleFonts.heebo(
          color: active ? whiteColor : mutedTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        backgroundColor: secondaryColor,
        selectedColor: color,
        side: BorderSide(color: active ? color : priceCardBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          _chip(ProductPtString.filterAll, null, slateGray),
          _chip(
            ItemCategory.products.label,
            ItemCategory.products,
            productPillColor,
          ),
          _chip(
            ItemCategory.services.label,
            ItemCategory.services,
            cartAccentColor,
          ),
        ],
      ),
    );
  }
}
