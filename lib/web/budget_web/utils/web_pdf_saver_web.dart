import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Implementação Web do download de PDF: cria um `Blob` e dispara o download
/// no navegador via um `<a download>`. Reutiliza os bytes já gerados pelo
/// `PdfGenerateUseCase.patternPDFBytes` — nenhuma regra de negócio do PDF é
/// duplicada aqui.
///
/// Usa `package:web` + `dart:js_interop` (a API Web moderna do Flutter),
/// em vez do `dart:html` legado.
void savePdfBytesWeb(Uint8List bytes, String fileName) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
