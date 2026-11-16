import 'package:oflite/modules/pdf/domain/utils/pdf_safe_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Adiciona ao [grid] uma linha lógica cujo texto da coluna 0 pode ser longo.
///
/// O Syncfusion só quebra uma linha da grade entre páginas quando ela é maior
/// que a página inteira; caso contrário empurra a linha toda para a próxima
/// página, deixando um espaço em branco. Aqui o texto da coluna 0 é quebrado
/// em várias linhas da grade (uma por linha de texto), e o restante de
/// [cells] vai só na primeira. Depois de aplicar o estilo das linhas, chame
/// [pdfJoinRows] com o retorno para remover bordas/espaços entre elas.
///
/// [font] e [horizontalPadding] devem ser os mesmos do estilo da célula.
List<PdfGridRow> pdfAddWrappedRows(
  PdfGrid grid, {
  required List<Object?> cells,
  required PdfFont font,
  required double horizontalPadding,
}) {
  final width = grid.columns[0].width - horizontalPadding - 2;
  final lines = _wrap(pdfSafeText(cells.first), font, width);
  final rows = <PdfGridRow>[];
  for (var i = 0; i < lines.length; i++) {
    final row = grid.rows.add();
    row.cells[0].value = lines[i];
    if (i == 0) {
      for (var c = 1; c < cells.length; c++) {
        row.cells[c].value = pdfSafeText(cells[c]);
      }
    }
    rows.add(row);
  }
  return rows;
}

/// Faz as [rows] (retorno de [pdfAddWrappedRows]) parecerem uma célula só:
/// sem borda nem padding vertical entre elas. Chamar depois do estilo aplicado.
void pdfJoinRows(List<PdfGridRow> rows) {
  if (rows.length < 2) return;
  // Largura 0: o Syncfusion soma a largura da borda na altura da linha, mesmo
  // transparente (`PdfPens.transparent` tem largura 1 → +4pt por linha).
  final noBorder = PdfPen(PdfColor(0, 0, 0, 0), width: 0);
  for (var i = 0; i < rows.length; i++) {
    final first = i == 0;
    final last = i == rows.length - 1;
    for (var c = 0; c < rows[i].cells.count; c++) {
      final cell = rows[i].cells[c];
      final base = cell.style;
      final pad = base.cellPadding;
      cell.style = PdfGridCellStyle(
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
  }
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
