import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card de item da lista de preço.
///
/// Component `Stateless` puro — recebe o item ([ProductPriceModel]), o
/// conversor de moeda, o flag `checkBoxAppear` (checkbox de exclusão) e os
/// callbacks (`onLongPress`, `onTap`, `onToggleDelete`). Não conhece o
/// ViewModel nem services.
class ProductPriceCard extends StatelessWidget {
  const ProductPriceCard({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.checkBoxAppear,
    required this.onLongPress,
    required this.onTap,
    required this.onToggleDelete,
  });

  final ProductPriceModel item;
  final ConvertCoinRepository moneyConvert;
  final bool checkBoxAppear;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback onToggleDelete;

  @override
  Widget build(BuildContext context) {
    // Validação da categoria para colorir a pílula de acordo com o design (mantendo cores do tema)
    final bool isProduct =
        ItemCategory.fromValue(item.categoria) == ItemCategory.products;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2A2A3C), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox de remoção no lado esquerdo (modo exclusão)
                if (checkBoxAppear)
                  Transform.scale(
                    scale: 1.6,
                    child: Checkbox(
                      side: const BorderSide(color: whiteColor),
                      checkColor: bgColor,
                      activeColor: whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      value: item.checkBox ?? false,
                      onChanged: (bool? newValue) => onToggleDelete(),
                    ),
                  ),

                if (checkBoxAppear) const SizedBox(width: 12),

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
                          color:
                              isProduct
                                  ? const Color(0xFF9C27B0)
                                  : const Color(0xFF00BFA5),
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
                          color: Color(0xFFB388FF),
                          letterSpacing: 0,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Indicador lateral direito (fora do modo exclusão)
                if (!checkBoxAppear)
                  Transform.scale(
                    scale: 1.4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFB388FF).withValues(alpha: 0.8),
                          width: 2.2,
                        ),
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
