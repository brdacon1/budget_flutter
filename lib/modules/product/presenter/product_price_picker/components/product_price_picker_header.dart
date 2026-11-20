import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';

import 'product_price_picker_category_filter.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Cabeçalho do picker no visual da tela de lista de preço: handle, título,
/// fechar, a mesma busca (`CupertinoSearchTextField`) e o filtro por
/// categoria.
class ProductPricePickerHeader extends StatelessWidget {
  const ProductPricePickerHeader({
    super.key,
    required this.title,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClose,
    required this.category,
    required this.onCategoryChanged,
  });

  final String title;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClose;
  final ItemCategory? category;
  final ValueChanged<ItemCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: sheetHandleColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 4, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.heebo(
                    color: whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: whiteColor, size: 28),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Container(
          height: 50.0,
          margin: const EdgeInsets.only(right: 17.0, left: 17.0, bottom: 10),
          child: CupertinoSearchTextField(
            placeholder: ProductPtString.searchHint,
            style: const TextStyle(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
            backgroundColor: Colors.white12,
            itemColor: whiteColor,
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ),
        ProductPricePickerCategoryFilter(
          selected: category,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
