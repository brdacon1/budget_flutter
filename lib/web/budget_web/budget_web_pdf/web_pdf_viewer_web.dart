import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Pré-visualização de PDF no Flutter Web usando o **visualizador nativo do
/// navegador**.
///
/// Em vez do `SfPdfViewer.memory` (que no Flutter Web/CanvasKit costuma ficar
/// em branco/sem scroll), criamos um Blob URL a partir dos bytes do PDF e o
/// embutimos num `<iframe>` via `HtmlElementView` (platform view). O
/// navegador então renderiza o PDF com a mesma UX de qualquer PDF na web:
/// scroll, zoom, download e impressão nativos — muito mais confiável que
/// qualquer lib Flutter de viewer web.
///
/// O Blob URL é revogado no `dispose` para não vazar memória. A regra de
/// negócio do PDF (bytes gerados pelo `PdfGenerateUseCase`) não é tocada
/// aqui — este widget apenas exibe bytes já prontos.
class WebPdfViewer extends StatefulWidget {
  const WebPdfViewer({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<WebPdfViewer> createState() => _WebPdfViewerState();
}

class _WebPdfViewerState extends State<WebPdfViewer> {
  // Cada instância precisa de um viewType único para registrar sua própria
  // factory no platform view registry.
  static int _counter = 0;
  late final String _viewType = 'web-pdf-viewer-${_counter++}';
  late final String _blobUrl;

  @override
  void initState() {
    super.initState();
    final blob = web.Blob(
      <JSAny>[widget.bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    _blobUrl = web.URL.createObjectURL(blob);
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        // `#zoom=page-fit` pede ao visualizador nativo de PDF do navegador
        // que abra já encaixando a página na tela — evita o "zoom absurdo"
        // (PDF enorme, só aparecendo um pedaço) especialmente em telas de
        // celular. Suportado pelo visualizador do Chrome/Edge (e Firefox);
        // onde não for suportado, é simplesmente ignorado (não quebra).
        ..src = '$_blobUrl#zoom=page-fit'
        ..title = 'PDF'
        // O iframe ocupa toda a área do HtmlElementView (que recebe
        // constraints tight do Stack/Positioned.fill no view pai).
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  @override
  void dispose() {
    web.URL.revokeObjectURL(_blobUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
