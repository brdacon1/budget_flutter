import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:oflite/shared/common/utils/image_normalizer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/utils/dio_client.dart';
import 'package:path_provider/path_provider.dart';

/// ÚNICO lugar do módulo com `image_picker`, `image_cropper`, Dio e
/// Firebase Storage para o logotipo.
class ImageLogoRemoteDatasource {
  final DioClient _dio;
  final FirebaseStorage _storage;

  ImageLogoRemoteDatasource({DioClient? dio, FirebaseStorage? storage})
      : _dio = dio ?? DioClient(),
        _storage = storage ?? FirebaseStorage.instance;

  Future<String?> pickImage({required bool camera}) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    return file?.path;
  }

  /// Baixa a imagem já cadastrada e grava uma cópia local pronta para o
  /// cropper. Devolve `null` se o download falhar ou os bytes não forem
  /// uma imagem válida.
  Future<String?> downloadForCrop(String url) async {
    final response = await _dio.dioClientAuth.get(url);
    if (response.statusCode != 200) return null;

    final png = await _normalize(response.data as Uint8List);
    if (png == null) return null;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(png);
    return path;
  }

  /// No iOS o `FLTImageCropperPlugin` aborta o app
  /// (NSInternalInconsistencyException em UIGraphicsBeginImageContext) com
  /// imagens inválidas/0x0 ou enormes. Decodifica, limita o lado maior a
  /// [maxSide] e re-codifica em PNG.
  Future<Uint8List?> _normalize(Uint8List bytes, {int maxSide = 2048}) async {
    if (bytes.isEmpty) return null;
    try {
      final probe = await ui.instantiateImageCodec(bytes);
      final first = (await probe.getNextFrame()).image;
      final w = first.width, h = first.height;
      first.dispose();
      if (w == 0 || h == 0) return null;

      final longest = w > h ? w : h;
      final scale = longest > maxSide ? maxSide / longest : 1.0;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: (w * scale).round(),
        targetHeight: (h * scale).round(),
      );
      final image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<String?> cropImage(
    String path, {
    required String androidTitle,
    required String iosTitle,
  }) async {
    final safePath = await normalizeImageFile(path);
    if (safePath == null) return null;
    final cropped = await ImageCropper().cropImage(
      sourcePath: safePath,
      maxWidth: 2048,
      maxHeight: 2048,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: androidTitle,
          toolbarColor: const Color(0xFF2A2D3E),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: iosTitle),
      ],
    );
    return cropped?.path;
  }

  /// Envia o arquivo em [path] como `fileName` na raiz do Storage e devolve
  /// a URL de download.
  Future<String> upload(String path, String fileName) async {
    final ref = _storage.ref().child(fileName);
    final snapshot = await ref.putFile(File(path));
    return snapshot.ref.getDownloadURL();
  }

  Future<void> delete(String storagePath) =>
      _storage.ref().child(storagePath).delete();
}
