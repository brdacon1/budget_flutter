import 'dart:async';
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
  // Atrasa a revogação do Blob URL: alguns navegadores iniciam o download
  // de forma assíncrona e, se o URL for revogado logo após o `click()`, o
  // download pode abortar. Usar `Future.delayed` (timer normal do Dart,
  // funciona no Web) dá uma janela curta antes de liberar o blob — sem vazar
  // memória por muito tempo.
  Future.delayed(const Duration(seconds: 4), () {
    web.URL.revokeObjectURL(url);
  });
}

/// Abre o PDF em uma **nova aba** do navegador, usando o visualizador nativo
/// cheio do browser. É o caminho mais confiável no mobile, onde o `<iframe>`
/// embutido (platform view) costuma limitar a navegação entre páginas.
///
/// Cria um Blob URL temporário e chama `window.open`. Como é disparado por
/// um toque no botão (gesto do usuário), o bloqueador de pop-ups não
/// bloqueia. O Blob URL é revogado depois de alguns segundos (a aba aberta
/// já carregou o conteúdo até lá).
void openPdfInNewTabWeb(Uint8List bytes) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  web.window.open(url, '_blank');
  Future.delayed(const Duration(seconds: 6), () {
    web.URL.revokeObjectURL(url);
  });
}
