/// R5: interpreta um valor digitado (`1.234,56`, `1234.56`, `R$ 500`).
/// Devolve `null` se o texto não for só um valor positivo.
class ParseMoneyInputUsecase {
  const ParseMoneyInputUsecase();

  static final _trailingValue = RegExp(
    r'^(.*?)[\s\-–:]+((?:r\$)?\s*\d[\d.,]*)$',
    caseSensitive: false,
  );

  /// Legenda enviada com o arquivo → nome e/ou valor do comprovante.
  /// - `"R$ 500"` → só valor;
  /// - `"Pix entrada R$ 500"` / `"Entrada - 150,00"` → nome + valor;
  /// - `"Pagamento antecipado"` → só nome.
  ({String? name, double? value}) caption(String? text) {
    final t = (text ?? '').trim();
    if (t.isEmpty) return (name: null, value: null);
    final whole = call(t);
    if (whole != null) return (name: null, value: whole);
    final m = _trailingValue.firstMatch(t);
    if (m != null) {
      final value = call(m.group(2));
      final name = m.group(1)!.trim();
      if (value != null && name.isNotEmpty) return (name: name, value: value);
    }
    return (name: t, value: null);
  }

  static final _valid = RegExp(r'^(r\$)?\s*\d[\d.,]*$');

  double? call(String? input) {
    var s = (input ?? '').trim().toLowerCase().replaceAll(' ', '');
    if (s.isEmpty || !_valid.hasMatch(s)) return null;
    s = s.replaceFirst(r'r$', '');
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    if (lastComma > lastDot) {
      // vírgula decimal (pt-BR): pontos são milhar
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (lastDot > lastComma && lastComma >= 0) {
      // ponto decimal (en): vírgulas são milhar
      s = s.replaceAll(',', '');
    } else if (lastDot >= 0 && s.length - lastDot - 1 == 3) {
      // "1.500" → milhar
      s = s.replaceAll('.', '');
    }
    final v = double.tryParse(s);
    if (v == null || v <= 0) return null;
    return (v * 100).roundToDouble() / 100;
  }
}
