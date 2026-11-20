import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card de item no picker, no mesmo visual do card da lista de preço.
/// Marcado mostra `quantidade × preço = total`. Tocar marca (abre
/// quantidade) ou desmarca.
class ProductPricePickerCard extends StatelessWidget {
  const ProductPricePickerCard({
    super.key,
    required this.item,
    required this.selected,
    required this.quantity,
    required this.moneyConvert,
    required this.onTap,
  });

  final ProductPriceModel item;
  final bool selected;
  final double? quantity;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onTap;

  String _formatQty(double q) =>
      q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toString();

  @override
  Widget build(BuildContext context) {
    final isProduct =
        ItemCategory.fromValue(item.categoria) == ItemCategory.products;
    final price = item.preco ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priceCardBorderColor, width: 1.2),
      ),
      child: Material(
        color: transparentColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isProduct ? productPillColor : cartAccentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.categoria}',
                          style: const TextStyle(
                            color: whiteColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.descricao}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selected && quantity != null
                            ? '${_formatQty(quantity!)} × ${moneyConvert.convertFromDouble(price)} = ${moneyConvert.convertFromDouble(quantity! * price)}'
                            : moneyConvert.convertFromDouble(price),
                        style: const TextStyle(
                          color: priceTextColor,
                          letterSpacing: 0,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Transform.scale(
                  scale: 1.6,
                  child: Checkbox(
                    side: const BorderSide(color: whiteColor),
                    checkColor: bgColor,
                    activeColor: whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    value: selected,
                    onChanged: (_) => onTap(),
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
