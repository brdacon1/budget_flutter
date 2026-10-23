import 'package:flutter/material.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal inferior para digitar um valor (ex.: quantidade).
///
/// Substitui o antigo `AlertDialog` de "Defina quantidade". Bottom modal que
/// acompanha o teclado, fundo branco, campo no padrão do projeto (cinza
/// máximo) e botão de confirmação. Retorna o valor digitado via
/// `Navigator.pop(context, value)` ou `null` ao cancelar.
class TextInputBottomModalWidget extends StatefulWidget {
  const TextInputBottomModalWidget({
    super.key,
    required this.title,
    this.hintText = 'Digite a quantidade',
    this.keyboardType = TextInputType.number,
    this.maxLength = 10,
    this.buttonLabel = 'OK',
  });

  final String title;
  final String hintText;
  final TextInputType keyboardType;
  final int? maxLength;
  final String buttonLabel;

  @override
  State<TextInputBottomModalWidget> createState() =>
      _TextInputBottomModalWidgetState();
}

class _TextInputBottomModalWidgetState extends State<TextInputBottomModalWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: widget.title,
      buttonLabel: _submitting ? 'Salvando...' : widget.buttonLabel,
      onButtonPressed: _handleSubmit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF9E9E9E), width: 2),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            autofocus: true,
            decoration: InputDecoration(
              enabledBorder: InputBorder.none,
              border: InputBorder.none,
              counterText: '',
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            style: TextStyle(
              color: AppBottomModal.grayColor,
              fontWeight: FontWeight.bold,
            ),
            onSubmitted: (_) => _handleSubmit(),
          ),
        ),
      ),
    );
  }
}

/// Helper que abre o [TextInputBottomModalWidget] e retorna o valor digitado.
Future<String?> showTextInputBottomModal(
  BuildContext context, {
  required String title,
  String hintText = 'Digite a quantidade',
  TextInputType keyboardType = TextInputType.number,
  int? maxLength = 10,
  String buttonLabel = 'OK',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TextInputBottomModalWidget(
      title: title,
      hintText: hintText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      buttonLabel: buttonLabel,
    ),
  );
}
