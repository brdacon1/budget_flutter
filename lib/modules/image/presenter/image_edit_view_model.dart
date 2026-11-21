import 'package:flutter/foundation.dart';
import 'package:oflite/modules/image/domain/repository/image_logo_repository.dart';
import 'package:oflite/modules/image/domain/usecase/crop_logo_usecase.dart';
import 'package:oflite/modules/image/domain/usecase/delete_logo_usecase.dart';
import 'package:oflite/modules/image/domain/usecase/upload_logo_usecase.dart';

class ImageEditViewModel extends ChangeNotifier {
  final ImageLogoRepository _repository;
  final CropLogoUsecase _crop;
  final UploadLogoUsecase _upload;
  final DeleteLogoUsecase _delete;

  ImageEditViewModel(this._repository, this._crop, this._upload, this._delete);

  String? pickedPath;
  String? croppedPath;
  String? fileName;
  String? initialImageUrl;

  bool get hasImage =>
      croppedPath != null || pickedPath != null || initialImageUrl != null;

  void loadInitialImage(String? fotoId, String? logoName) {
    if (fotoId == null || fotoId.isEmpty) return;

    initialImageUrl = fotoId;
    notifyListeners();
  }

  /// Seleciona o logotipo pela câmera ou galeria.
  Future<void> pickImage({required bool camera}) async {
    final path = await _repository.pickImage(camera: camera);
    if (path == null) return;

    pickedPath = path;
    croppedPath = null;
    initialImageUrl = null;
    notifyListeners();
  }

  Future<void> cropImage() async {
    final path = await _crop(localPath: pickedPath, remoteUrl: initialImageUrl);
    if (path == null) return;

    croppedPath = path;
    initialImageUrl = null;
    notifyListeners();
  }

  /// Devolve a URL do logotipo enviado, ou `''` se não houver/falhar.
  Future<String> uploadImageToFirebase() async {
    final path = croppedPath ?? pickedPath;
    if (path == null) return '';

    final result = await _upload(path);
    if (result == null) return '';
    fileName = result.fileName;
    return result.url;
  }

  Future<void> deleteImage(String? imageName) => _delete(imageName);

  void resetImage() {
    pickedPath = null;
    croppedPath = null;
    fileName = null;
    initialImageUrl = null;
    notifyListeners();
  }

  void resetCrop() {
    croppedPath = null;
    notifyListeners();
  }
}
