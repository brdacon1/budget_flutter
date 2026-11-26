import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/business_segment.dart';
import 'package:oflite/modules/product/presenter/product_price_creator/components/product_price_field.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Passo 1 do modal de ramo: chips com os ramos e, em "Outro", campo de texto.
class ProductSegmentPicker extends StatelessWidget {
  const ProductSegmentPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.customController,
    required this.enabled,
    this.errorText,
  });

  final BusinessSegment? selected;
  final ValueChanged<BusinessSegment> onSelected;
  final TextEditingController customController;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ProductPtString.segmentSubtitle,
          style: const TextStyle(color: AppBottomModal.grayColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in BusinessSegment.choices)
              Opacity(
                opacity: enabled || selected == s ? 1 : 0.5,
                child: ChoiceChip(
                  label: Text(s.label),
                  selected: selected == s,
                  selectedColor: buttonColor,
                  backgroundColor: whiteColor,
                  disabledColor: whiteColor,
                  side: const BorderSide(
                    color: modalFieldBorderColor,
                    width: 2,
                  ),
                  labelStyle: TextStyle(
                    color:
                        selected == s ? blackColor : AppBottomModal.grayColor,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: enabled ? (_) => onSelected(s) : null,
                ),
              ),
          ],
        ),
        if (selected == BusinessSegment.other) ...[
          const SizedBox(height: 16),
          ProductPriceField(
            controller: customController,
            hintText: ProductPtString.segmentCustomHint,
            icon: Icons.work_outline,
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(errorText!, style: const TextStyle(color: statusRejectedColor)),
        ],
      ],
    );
  }
}
