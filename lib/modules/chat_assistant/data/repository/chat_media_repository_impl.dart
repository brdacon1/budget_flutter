import 'package:photo_manager/photo_manager.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/device_media_datasource.dart';
import 'package:oflite/modules/chat_assistant/data/datasource/shared_media_datasource.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/gallery_asset_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_media_repository.dart';

class ChatMediaRepositoryImpl implements ChatMediaRepository {
  final DeviceMediaDatasource _device;
  final SharedMediaDatasource _shared;

  ChatMediaRepositoryImpl(this._device, this._shared);

  static const _pageSize = 60;

  @override
  Future<bool> requestGalleryPermission() => _device.requestGalleryPermission();

  @override
  Future<({bool camera, bool gallery})> requestMediaPermissions() =>
      _device.requestMediaPermissions();

  @override
  Future<String?> cropImage(String path, {required String title}) =>
      _device.cropImage(path, title: title);

  @override
  Future<void> openSettings() => _device.openSettings();

  @override
  Future<List<GalleryAlbumEntity>> albums() async => [
    for (final a in await _device.albums())
      GalleryAlbumEntity(id: a.id, name: a.name, count: a.count),
  ];

  @override
  Future<List<GalleryAssetEntity>> galleryPage(String albumId, int page) async {
    final assets = await _device.page(albumId, page, _pageSize);
    return [
      for (final a in assets)
        GalleryAssetEntity(
          id: a.id,
          // Foto só no iCloud: permite baixar (progressHandler) e nunca
          // propaga o erro 1006 do CloudPhotoLibrary — devolve null.
          thumbnail: () async {
            try {
              return await a.thumbnailDataWithSize(
                const ThumbnailSize.square(300),
                progressHandler: PMProgressHandler(),
              );
            } catch (_) {
              return null;
            }
          },
          filePath: () async {
            try {
              final f = await a.loadFile(
                isOrigin: false,
                progressHandler: PMProgressHandler(),
              );
              return f?.path;
            } catch (_) {
              return null;
            }
          },
        ),
    ];
  }

  @override
  Future<RawMediaFile?> takePhoto() => _device.takePhoto();

  @override
  Future<RawMediaFile?> pickPdf() => _device.pickPdf();

  @override
  Future<List<RawMediaFile>> pickImages(int limit) => _device.pickImages(limit);

  @override
  Future<List<RawMediaFile>> initialShared() => _shared.initialMedia();

  @override
  Stream<List<RawMediaFile>> sharedStream() => _shared.mediaStream();

  @override
  Future<void> resetShared() => _shared.reset();
}
