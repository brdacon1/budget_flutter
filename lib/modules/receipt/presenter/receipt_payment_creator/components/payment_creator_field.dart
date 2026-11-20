import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Campo de formulário reutilizável do modal de criação/edição de pagamento.
///
/// Segue o **padrão visual dos bottom modals** do app:
/// - fundo **branco**;
/// - borda cinza `0xFF9E9E9E` (espessura 2);
/// - texto, ícone e hint em [AppBottomModal.grayColor] (cinza máximo);
/// - ocupa a largura total (auto-height).
class PaymentCreatorField extends StatelessWidget {
  const PaymentCreatorField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.onTap,
    this.readOnly = false,
    this.suffixIcon,
    this.keyboardType,
    this.maxLines,
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;

  /// Mensagem de validação exibida abaixo do campo (borda fica vermelha).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final field = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? Colors.red : const Color(0xFF9E9E9E),
          width: 2,
        ),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        enableInteractiveSelection: true,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onTap: onTap,
        decoration: InputDecoration(
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppBottomModal.grayColor),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        style: const TextStyle(
          color: AppBottomModal.grayColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    if (!hasError) return field;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        field,
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 4),
          child: Text(
            errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
