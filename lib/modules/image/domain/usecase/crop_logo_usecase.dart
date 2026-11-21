import 'package:oflite/modules/image/domain/repository/image_logo_repository.dart';
import 'package:oflite/modules/image/presenter/strings/image_pt_string.dart';

/// Recorta o logotipo: arquivo local escolhido agora ou, se não houver,
/// a imagem já cadastrada em [remoteUrl]. Devolve o caminho recortado.
class CropLogoUsecase {
  final ImageLogoRepository _repository;

  const CropLogoUsecase(this._repository);

  Future<String?> call({String? localPath, String? remoteUrl}) async {
    final source = localPath ??
        (remoteUrl == null ? null : await _repository.downloadForCrop(remoteUrl));
    if (source == null) return null;

    return _repository.cropImage(
      source,
      androidTitle: ImageStrings.cropImageTitle,
      iosTitle: ImageStrings.cropperTitle,
    );
  }
}
