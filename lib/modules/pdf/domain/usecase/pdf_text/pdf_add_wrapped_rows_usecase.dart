import 'package:oflite/modules/pdf/domain/usecase/pdf_text/pdf_sanitize_text_usecase.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Adiciona ao [PdfGrid] um registro (ex.: um pagamento) cujo texto da
/// coluna 0 pode ser longo, sem deixar página em branco.
///
/// Regra: o Syncfusion só quebra uma linha da grade entre páginas quando ela é
/// maior que a página inteira; caso contrário empurra a linha toda para a
/// próxima página. Aqui o texto da coluna 0 é quebrado em várias linhas da
/// grade (uma por linha de texto) que parecem uma célula só (sem borda nem
/// padding entre elas). As demais [cells] vão só na primeira linha.
class PdfAddWrappedRowsUsecase {
  final PdfSanitizeTextUsecase _sanitizeText;

  const PdfAddWrappedRowsUsecase(this._sanitizeText);

  /// Grade sem fonte definida usa Helvetica 8 (padrão do Syncfusion).
  static PdfFont get _gridDefaultFont =>
      PdfStandardFont(PdfFontFamily.helvetica, 8);

  void call(
    PdfGrid grid, {
    required List<Object?> cells,
    required PdfGridCellStyle style,
  }) {
    final lines = _wrap(
      _sanitizeText(cells.first),
      style.font ?? _gridDefaultFont,
      grid.columns[0].width - _horizontalSpace(grid, style),
    );
    for (var i = 0; i < lines.length; i++) {
      final row = grid.rows.add();
      row.cells[0].value = lines[i];
      if (i == 0) {
        for (var c = 1; c < cells.length; c++) {
          row.cells[c].value = _sanitizeText(cells[c]);
        }
      }
      final rowStyle =
          lines.length == 1
              ? style
              : _joinedStyle(
                style,
                first: i == 0,
                last: i == lines.length - 1,
              );
      for (var c = 0; c < row.cells.count; c++) {
        row.cells[c].style = rowStyle;
      }
    }
  }

  /// Mesmo cálculo de largura útil que o Syncfusion faz na célula.
  double _horizontalSpace(PdfGrid grid, PdfGridCellStyle style) {
    final pad = style.cellPadding;
    if (pad == null) {
      return grid.style.cellPadding.left + grid.style.cellPadding.right;
    }
    return pad.left +
        pad.right +
        style.borders.left.width +
        style.borders.right.width;
  }

  PdfGridCellStyle _joinedStyle(
    PdfGridCellStyle base, {
    required bool first,
    required bool last,
  }) {
    // Largura 0: o Syncfusion soma a largura da borda na altura da linha,
    // mesmo transparente (`PdfPens.transparent` tem largura 1 → +4pt).
    final noBorder = PdfPen(PdfColor(0, 0, 0, 0), width: 0);
    final pad = base.cellPadding;
    return PdfGridCellStyle(
        font: base.font,
        textBrush: base.textBrush,
        textPen: base.textPen,
        backgroundBrush: base.backgroundBrush,
        format: base.stringFormat,
        cellPadding: PdfPaddings(
          left: pad?.left ?? 0,
          right: pad?.right ?? 0,
          top: first ? (pad?.top ?? 0) : 0,
          bottom: last ? (pad?.bottom ?? 0) : 0,
        ),
      )
      ..borders.left = base.borders.left
      ..borders.right = base.borders.right
      ..borders.top = first ? base.borders.top : noBorder
      ..borders.bottom = last ? base.borders.bottom : noBorder;
  }

  List<String> _wrap(String text, PdfFont font, double width) {
    double w(String s) => font.measureString(s).width;
    final lines = <String>[];
    for (final paragraph in text.split('\n')) {
      var line = '';
      for (var word in paragraph.split(' ')) {
        // Palavra maior que a coluna: quebra por caractere.
        while (w(word) > width) {
          var cut = 1;
          while (cut < word.length && w(word.substring(0, cut + 1)) <= width) {
            cut++;
          }
          if (line.isNotEmpty) {
            lines.add(line);
            line = '';
          }
          lines.add(word.substring(0, cut));
          word = word.substring(cut);
        }
        final candidate = line.isEmpty ? word : '$line $word';
        if (w(candidate) <= width) {
          line = candidate;
        } else {
          lines.add(line);
          line = word;
        }
      }
      lines.add(line);
    }
    return lines;
  }
}
