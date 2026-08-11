import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Stub não-Web do [WebPdfViewer].
///
/// Este entry point (`main_web.dart`) é Web-only, mas o import condicional
/// precisa de um fallback compilável em outras plataformas. No
/// mobile/desktop cai no `SfPdfViewer.memory` (que lá funciona normalmente).
class WebPdfViewer extends StatelessWidget {
  const WebPdfViewer({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.memory(bytes);
  }
}
