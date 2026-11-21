import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card de item da lista de preço.
///
/// Component `Stateless` puro — recebe o item ([ProductPriceModel]), o
/// conversor de moeda, se está [selected] e os callbacks (`onTap` edita,
/// `onToggleSelect` marca para remoção pelo check circular). Não conhece o
/// ViewModel nem services.
class ProductPriceCard extends StatelessWidget {
  const ProductPriceCard({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.selected,
    required this.onTap,
    required this.onToggleSelect,
  });

  final ProductPriceModel item;
  final ConvertCoinRepository moneyConvert;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    // Validação da categoria para colorir a pílula de acordo com o design (mantendo cores do tema)
    final bool isProduct =
        ItemCategory.fromValue(item.categoria) == ItemCategory.products;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: selected ? buttonColor.withValues(alpha: 0.08) : secondaryColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: selected ? buttonColor : priceCardBorderColor,
          width: 1.2,
        ),
      ),
      child: Material(
        color: transparentColor,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Informações do item alinhadas à esquerda (Tag, Descrição e Preço)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag superior estilo pílula arredondada
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

                      // Descrição do produto/serviço
                      Text(
                        '${item.descricao}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Preço formatado usando o repositório original
                      Text(
                        moneyConvert.convertFromDouble(item.preco ?? 0),
                        style: const TextStyle(
                          color: priceTextColor,
                          letterSpacing: 0,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 1),

                // Check circular de remoção (área de toque de 48px).
                InkResponse(
                  onTap: onToggleSelect,
                  radius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? buttonColor : transparentColor,
                        border: Border.all(
                          color: selected ? buttonColor : priceTextColor,
                          width: 2.2,
                        ),
                      ),
                      child:
                          selected
                              ? const Icon(
                                Icons.check,
                                size: 16,
                                color: bgColor,
                              )
                              : null,
                    ),
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
