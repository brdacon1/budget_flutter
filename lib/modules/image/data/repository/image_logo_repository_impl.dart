import 'package:oflite/modules/image/data/datasource/image_logo_remote_datasource.dart';
import 'package:oflite/modules/image/domain/repository/image_logo_repository.dart';

class ImageLogoRepositoryImpl implements ImageLogoRepository {
  final ImageLogoRemoteDatasource _datasource;

  ImageLogoRepositoryImpl(this._datasource);

  @override
  Future<String?> pickImage({required bool camera}) =>
      _datasource.pickImage(camera: camera);

  @override
  Future<String?> downloadForCrop(String url) => _datasource.downloadForCrop(url);

  @override
  Future<String?> cropImage(
    String path, {
    required String androidTitle,
    required String iosTitle,
  }) =>
      _datasource.cropImage(path, androidTitle: androidTitle, iosTitle: iosTitle);

  @override
  Future<String> upload(String path, String fileName) =>
      _datasource.upload(path, fileName);

  @override
  Future<void> delete(String storagePath) => _datasource.delete(storagePath);
}
