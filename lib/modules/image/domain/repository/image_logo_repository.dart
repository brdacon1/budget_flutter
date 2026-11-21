abstract class ImageLogoRepository {
  Future<String?> pickImage({required bool camera});
  Future<String?> downloadForCrop(String url);
  Future<String?> cropImage(
    String path, {
    required String androidTitle,
    required String iosTitle,
  });
  Future<String> upload(String path, String fileName);
  Future<void> delete(String storagePath);
}
