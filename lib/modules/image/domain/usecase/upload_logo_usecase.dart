import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/image/domain/repository/image_logo_repository.dart';

/// Envia o logotipo como `{userId}.jpg`. Devolve URL e nome do arquivo, ou
/// `null` em caso de falha.
class UploadLogoUsecase {
  final ImageLogoRepository _repository;
  final UserRepository _user;

  const UploadLogoUsecase(this._repository, this._user);

  Future<({String url, String fileName})?> call(String path) async {
    try {
      final fileName = '${_user.selectUser.value?.user}.jpg';
      final url = await _repository.upload(path, fileName);
      return (url: url, fileName: fileName);
    } catch (_) {
      return null;
    }
  }
}
