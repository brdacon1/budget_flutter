import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Passo 2 do modal de ramo: lista gerada, com opção de remover itens.
class ProductSegmentReviewList extends StatelessWidget {
  const ProductSegmentReviewList({
    super.key,
    required this.items,
    required this.formatPrice,
    required this.onRemove,
    required this.enabled,
  });

  final List<ProductPriceModel> items;
  final String Function(double) formatPrice;
  final ValueChanged<int> onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ProductPtString.segmentReviewHint,
          style: const TextStyle(color: AppBottomModal.grayColor),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              items[i].descricao ?? '',
              style: const TextStyle(
                color: AppBottomModal.grayColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${formatPrice(items[i].preco ?? 0)} / ${items[i].medida}',
              style: const TextStyle(color: AppBottomModal.grayColor),
            ),
            trailing: IconButton(
              tooltip: ProductPtString.segmentRemoveTooltip,
              icon: const Icon(Icons.close, color: AppBottomModal.grayColor),
              onPressed: enabled ? () => onRemove(i) : null,
            ),
          ),
      ],
    );
  }
}
