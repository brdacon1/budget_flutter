// Barrel com import condicional: no Flutter Web usa a implementação que
// embute um `<iframe>` (visualizador nativo do navegador) via
// `HtmlElementView`; no mobile/desktop cai no stub com `SfPdfViewer`.
//
// O `SfPdfViewer.memory` não renderiza de forma confiável no Flutter Web
// (CanvasKit) — a pré-visualização fica em branco/sem scroll. O `<iframe>`
// apontando para um Blob URL entrega a mesma experiência do navegador
// (scroll, zoom, download, impressão), que é o que o cliente espera.
export 'web_pdf_viewer_io.dart'
    if (dart.library.html) 'web_pdf_viewer_web.dart';
