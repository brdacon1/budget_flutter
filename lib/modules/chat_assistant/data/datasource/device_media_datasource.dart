import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:image_cropper/image_cropper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oflite/shared/common/utils/image_normalizer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

/// ÚNICO lugar com `photo_manager`, `image_picker` e `file_selector`.
class DeviceMediaDatasource {
  final Map<String, AssetPathEntity> _albums = {};

  Future<bool> requestGalleryPermission() async {
    try {
      final state = await PhotoManager.requestPermissionExtend();
      return state.hasAccess;
    } on MissingPluginException {
      // Binário antigo sem o plugin (hot restart após adicionar o pacote).
      return false;
    }
  }

  /// Câmera + fotos. No Android a galeria é o Photo Picker do sistema, que
  /// não pede permissão (política do Play: sem READ_MEDIA_IMAGES). No iOS
  /// pede `photos`; acesso parcial conta como liberado.
  Future<({bool camera, bool gallery})> requestMediaPermissions() async {
    try {
      final gallery = [if (!Platform.isAndroid) Permission.photos];
      final result = await [Permission.camera, ...gallery].request();
      bool ok(PermissionStatus? s) => s != null && (s.isGranted || s.isLimited);
      return (
        camera: ok(result[Permission.camera]),
        gallery: gallery.isEmpty || gallery.any((p) => ok(result[p])),
      );
    } on MissingPluginException {
      return (camera: false, gallery: false);
    }
  }

  /// Recorte (mesma lib da tela de logo). Devolve o novo caminho ou `null`.
  ///
  /// Nunca abre dois recortes ao mesmo tempo: toques repetidos durante a
  /// espera derrubavam o app no iOS (`FLTImageCropperPlugin`).
  Future<String?> cropImage(String path, {required String title}) async {
    if (_cropping) return null;
    _cropping = true;
    try {
      return await _crop(path, title: title);
    } finally {
      _cropping = false;
    }
  }

  static bool _cropping = false;

  Future<String?> _crop(String path, {required String title}) async {
    final safePath = await normalizeImageFile(path);
    if (safePath == null) return null;
    final cropped = await ImageCropper().cropImage(
      sourcePath: safePath,
      maxWidth: 2048,
      maxHeight: 2048,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: const Color(0xFF2A2D3E),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: title),
      ],
    );
    return cropped?.path;
  }

  Future<void> openSettings() => PhotoManager.openSetting();

  /// Álbuns de imagens. O primeiro é "Recentes"/"Todas".
  Future<List<({String id, String name, int count})>> albums() async {
    final paths = await PhotoManager.getAssetPathList(type: RequestType.image);
    _albums
      ..clear()
      ..addEntries(paths.map((p) => MapEntry(p.id, p)));
    final out = <({String id, String name, int count})>[];
    for (final p in paths) {
      out.add((id: p.id, name: p.name, count: await p.assetCountAsync));
    }
    return out;
  }

  Future<List<AssetEntity>> page(String albumId, int page, int size) async {
    final album = _albums[albumId];
    if (album == null) return [];
    return album.getAssetListPaged(page: page, size: size);
  }

  Future<({String path, String? mime})?> takePhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    return file == null ? null : (path: file.path, mime: 'image/jpeg');
  }

  /// Photo Picker do sistema (Android), até [limit] imagens.
  Future<List<({String path, String? mime})>> pickImages(int limit) async {
    final files = await ImagePicker().pickMultiImage(
      limit: limit,
      imageQuality: 85,
    );
    return [for (final f in files) (path: f.path, mime: 'image/jpeg')];
  }

  Future<({String path, String? mime})?> pickPdf() async {
    const pdf = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
      uniformTypeIdentifiers: ['com.adobe.pdf'],
    );
    final file = await openFile(acceptedTypeGroups: const [pdf]);
    final path = file?.path;
    return path == null ? null : (path: path, mime: 'application/pdf');
  }
}
