/// Remove do texto os caracteres que `PdfStandardFont` (Helvetica/Times,
/// codificação Windows-1252) não desenha — ex.: `▖` (U+2596), emojis, outros
/// alfabetos. Sem isso o Syncfusion lança
/// `Invalid argument (The character is not supported by the font.)` e o PDF
/// não é gerado.
///
/// Regra: todo texto desenhado no PDF (dados do usuário e labels) passa por
/// aqui. O dado salvo no Firestore não é alterado.
class PdfSanitizeTextUsecase {
  const PdfSanitizeTextUsecase();

  /// Caracteres acima de U+00FF suportados pela codificação Windows-1252.
  static const String _win1252Extras = '€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ';

  String call(Object? value) {
    final text = value?.toString() ?? '';
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (rune < 256 || _win1252Extras.contains(char)) buffer.write(char);
    }
    return buffer.toString();
  }
}
