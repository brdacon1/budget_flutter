import 'package:oflite/modules/chat_assistant/domain/entity/gallery_asset_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_media_repository.dart';

/// Galeria do aparelho para o seletor de comprovantes.
class LoadGalleryUsecase {
  final ChatMediaRepository _media;

  const LoadGalleryUsecase(this._media);

  Future<bool> requestPermission() => _media.requestGalleryPermission();

  Future<void> openSettings() => _media.openSettings();

  /// Álbuns com pelo menos 1 foto; o primeiro é "Recentes".
  Future<List<GalleryAlbumEntity>> albums() async =>
      (await _media.albums()).where((a) => a.count > 0).toList();

  Future<List<GalleryAssetEntity>> page(String albumId, int page) =>
      _media.galleryPage(albumId, page);
}
