import 'package:oflite/modules/chat_assistant/domain/entity/gallery_asset_entity.dart';

abstract class ChatMediaRepository {
  Future<bool> requestGalleryPermission();

  /// Câmera + fotos, pedidas ao abrir o chat (modo IA).
  Future<bool> requestMediaPermissions();

  /// Recorta a imagem; `null` se o usuário cancelar.
  Future<String?> cropImage(String path, {required String title});

  Future<void> openSettings();

  Future<List<GalleryAlbumEntity>> albums();

  Future<List<GalleryAssetEntity>> galleryPage(String albumId, int page);

  Future<RawMediaFile?> takePhoto();

  Future<RawMediaFile?> pickPdf();

  Future<List<RawMediaFile>> initialShared();

  Stream<List<RawMediaFile>> sharedStream();

  Future<void> resetShared();
}
