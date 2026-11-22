import 'package:flutter/services.dart';

/// Formatter de UI: delega a máscara CPF/CNPJ dinâmica para [format]
/// (normalmente `FormatDocumentUsecase.partial`).
class DocumentInputFormatter extends TextInputFormatter {
  final String Function(String raw) format;

  DocumentInputFormatter(this.format);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = format(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
