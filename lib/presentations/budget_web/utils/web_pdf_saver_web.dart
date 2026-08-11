import 'dart:html' as html;
import 'dart:typed_data';

/// Implementação Web do download de PDF: cria um Blob e dispara o download
/// no navegador via um `<a download>`. Reutiliza os bytes já gerados pelo
/// `PdfGenerateUseCase.patternPDFBytes` — nenhuma regra de negócio do PDF
/// é duplicada aqui.
void savePdfBytesWeb(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
