/// Caracteres acima de U+00FF que as fontes padrão do PDF (Helvetica/Times,
/// codificação Windows-1252) conseguem desenhar.
const String _win1252Extras = '€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ';

/// Remove caracteres que `PdfStandardFont` não suporta (ex.: `▖` U+2596,
/// emojis, outros alfabetos). Sem isso o Syncfusion lança
/// `Invalid argument (The character is not supported by the font.)` e o PDF
/// não é gerado. Usar em todo texto desenhado (dados do usuário e labels).
String pdfSafeText(Object? value) {
  final text = value?.toString() ?? '';
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (rune < 256 || _win1252Extras.contains(char)) buffer.write(char);
  }
  return buffer.toString();
}
