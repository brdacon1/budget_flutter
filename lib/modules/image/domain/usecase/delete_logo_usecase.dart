import 'package:flutter/foundation.dart';
import 'package:oflite/modules/image/domain/repository/image_logo_repository.dart';

class DeleteLogoUsecase {
  final ImageLogoRepository _repository;

  const DeleteLogoUsecase(this._repository);

  Future<void> call(String? imageName) async {
    if (imageName == null || imageName.isEmpty) return;
    try {
      await _repository.delete('images/$imageName.jpg');
    } catch (e) {
      debugPrint('Erro ao excluir a imagem: $e');
    }
  }
}
