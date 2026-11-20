import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Arquivos locais: tamanho e compressão de imagem (heic → jpg).
class ProofFileLocalDatasource {
  Future<int> sizeOf(String path) async {
    final file = File(path);
    return await file.exists() ? file.length() : 0;
  }

  /// Teto do arquivo enviado ao Storage.
  static const maxUploadBytes = 8 * 1024 * 1024;

  /// Comprime para JPG (lado maior até 2048 px) baixando a qualidade até
  /// ficar com no máximo 8 MB. Se a compressão falhar, devolve o original.
  Future<String> compressImage(String path) async {
    try {
      final dir = await getTemporaryDirectory();
      var side = 2048;
      for (final quality in const [80, 65, 50, 35, 25]) {
        final target =
            '${dir.path}/proof_${DateTime.now().microsecondsSinceEpoch}.jpg';
        final out = await FlutterImageCompress.compressAndGetFile(
          path,
          target,
          quality: quality,
          minWidth: side,
          minHeight: side,
          format: CompressFormat.jpeg,
        );
        if (out == null) return path;
        if (await out.length() <= maxUploadBytes) return out.path;
        if (quality <= 50) side = 1600;
      }
      return path;
    } catch (_) {
      return path;
    }
  }
}
