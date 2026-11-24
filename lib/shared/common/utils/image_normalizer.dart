import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

/// Conversão pura: grava em arquivo temporário um PNG válido da imagem em
/// [path], com o lado maior limitado a [maxSide]. Devolve `null` se a imagem
/// for inválida/0x0. Evita o abort do `FLTImageCropperPlugin` no iOS
/// (NSInternalInconsistencyException em UIGraphicsBeginImageContext).
Future<String?> normalizeImageFile(String path, {int maxSide = 2048}) async {
  try {
    final bytes = await File(path).readAsBytes();
    if (bytes.isEmpty) return null;
    // Caminho rápido: JPG/PNG já dentro do limite não precisam ser
    // re-codificados (isso era a espera antes de o recorte abrir). Só lê as
    // dimensões, sem decodificar a imagem inteira.
    final ext = path.toLowerCase();
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png')) {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      try {
        final d = await ui.ImageDescriptor.encoded(buffer);
        final longest = d.width > d.height ? d.width : d.height;
        final valid = d.width > 0 && d.height > 0;
        d.dispose();
        if (valid && longest <= maxSide) return path;
      } finally {
        buffer.dispose();
      }
    }
    final first =
        (await (await ui.instantiateImageCodec(bytes)).getNextFrame()).image;
    final w = first.width, h = first.height;
    first.dispose();
    if (w == 0 || h == 0) return null;
    final longest = w > h ? w : h;
    final scale = longest > maxSide ? maxSide / longest : 1.0;
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: (w * scale).round().clamp(1, maxSide),
      targetHeight: (h * scale).round().clamp(1, maxSide),
    );
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return null;
    final dir = await getTemporaryDirectory();
    final out = '${dir.path}/norm_${DateTime.now().microsecondsSinceEpoch}.png';
    await File(out).writeAsBytes(Uint8List.view(data.buffer));
    return out;
  } catch (_) {
    return null;
  }
}
