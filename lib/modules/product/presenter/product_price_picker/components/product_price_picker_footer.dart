import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Rodapé do picker: total dos itens selecionados + "Adicionar tudo".
class ProductPricePickerFooter extends StatelessWidget {
  const ProductPricePickerFooter({
    super.key,
    required this.total,
    required this.count,
    required this.loading,
    required this.onAddAll,
  });

  final String total;
  final int count;
  final bool loading;
  final VoidCallback onAddAll;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cartBarColor,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: cartAccentColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ProductPtString.pickerTotalLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: total,
                            style: const TextStyle(
                              color: whiteColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    ' / ${ProductPtString.pickerCount(count)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: blackColor,
                    disabledBackgroundColor: buttonColor.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: loading ? null : onAddAll,
                  child: Text(
                    loading
                        ? ProductPtString.pickerAdding
                        : ProductPtString.pickerAddAll,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
