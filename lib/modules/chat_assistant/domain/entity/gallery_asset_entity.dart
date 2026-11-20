import 'dart:typed_data';

/// Foto da galeria do aparelho (sem expor o SDK de mídia ao domain).
class GalleryAssetEntity {
  final String id;
  final Future<Uint8List?> Function() thumbnail;
  final Future<String?> Function() filePath;

  const GalleryAssetEntity({
    required this.id,
    required this.thumbnail,
    required this.filePath,
  });
}

/// Álbum da galeria.
class GalleryAlbumEntity {
  final String id;
  final String name;
  final int count;

  const GalleryAlbumEntity({
    required this.id,
    required this.name,
    required this.count,
  });
}

/// Arquivo cru vindo de câmera, documento ou compartilhamento.
typedef RawMediaFile = ({String path, String? mime});
