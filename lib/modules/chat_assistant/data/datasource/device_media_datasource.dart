import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:image_cropper/image_cropper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
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

  /// Câmera + fotos. No Android < 13 a galeria vem de `storage`; no 13+
  /// de `photos` (READ_MEDIA_IMAGES). Acesso parcial conta como liberado.
  Future<bool> requestMediaPermissions() async {
    try {
      final gallery = [
        Permission.photos,
        if (Platform.isAndroid) Permission.storage,
      ];
      final result = await [Permission.camera, ...gallery].request();
      bool ok(PermissionStatus? s) =>
          s != null && (s.isGranted || s.isLimited);
      return ok(result[Permission.camera]) &&
          gallery.any((p) => ok(result[p]));
    } on MissingPluginException {
      return false;
    }
  }

  /// Recorte (mesma lib da tela de logo). Devolve o novo caminho ou `null`.
  Future<String?> cropImage(String path, {required String title}) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
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
