import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal simples de quantidade do picker. Não fecha enquanto o [validator]
/// retornar erro (erro inline); devolve a quantidade já convertida (> 0).
class ProductPricePickerQuantityBottomModalWidget extends StatefulWidget {
  const ProductPricePickerQuantityBottomModalWidget({
    super.key,
    required this.validator,
    required this.parse,
  });

  final String? Function(String raw) validator;
  final double? Function(String raw) parse;

  @override
  State<ProductPricePickerQuantityBottomModalWidget> createState() =>
      _ProductPricePickerQuantityBottomModalWidgetState();
}

class _ProductPricePickerQuantityBottomModalWidgetState
    extends State<ProductPricePickerQuantityBottomModalWidget> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.validator(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(widget.parse(_controller.text));
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      scrollable: true,
      title: ProductPtString.qtyTitle,
      buttonLabel: ProductPtString.qtyConfirm,
      onButtonPressed: _submit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            LengthLimitingTextInputFormatter(10),
          ],
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
          cursorColor: AppBottomModal.grayColor,
          style: GoogleFonts.heebo(
            color: AppBottomModal.grayColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: ProductPtString.qtyInputHint,
            hintStyle: GoogleFonts.heebo(color: modalLabelColor, fontSize: 16),
            errorText: _error,
            errorStyle: GoogleFonts.heebo(
              color: statusRejectedColor,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: _border(buttonColor, 2),
            focusedBorder: _border(buttonColor, 2.5),
            errorBorder: _border(statusRejectedColor, 2),
            focusedErrorBorder: _border(statusRejectedColor, 2.5),
          ),
        ),
      ),
    );
  }
}

/// Abre o modal de quantidade. Retorna a quantidade (> 0) ou `null` se
/// o usuário fechar.
Future<double?> showProductPricePickerQuantityBottomModal(
  BuildContext context, {
  required String? Function(String raw) validator,
  required double? Function(String raw) parse,
}) {
  return showAppModal<double>(
    context,
    builder:
        (context) => ProductPricePickerQuantityBottomModalWidget(
          validator: validator,
          parse: parse,
        ),
  );
}
