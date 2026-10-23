import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as UID;

class ImageEditViewModel extends ChangeNotifier {
  XFile? pickedFile;
  CroppedFile? croppedFile;
  String? fileName;
  String? initialImageUrl;

  bool get hasImage =>
      croppedFile != null || pickedFile != null || initialImageUrl != null;

  void loadInitialImage(String? fotoId, String? logoName) {
    if (fotoId == null || fotoId.isEmpty) return;

    initialImageUrl = fotoId;
    print('ImageEditViewModel: initialImageUrl = $initialImageUrl');
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      this.pickedFile = pickedFile;
      croppedFile = null;
      initialImageUrl = null;
      notifyListeners();
    }
  }

  Future<void> cropImage() async {
    if (pickedFile == null && initialImageUrl == null) return;

    String sourcePath;
    if (pickedFile != null) {
      sourcePath = pickedFile!.path;
    } else {
      final response = await http.get(Uri.parse(initialImageUrl!));
      if (response.statusCode != 200) {
        print('Erro ao baixar imagem para cortar: ${response.statusCode}');
        return;
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final tempPath = '${appDir.path}/temp_crop_image.jpg';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(response.bodyBytes);
      sourcePath = tempPath;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cortar imagem',
          toolbarColor: const Color(0xFF2A2D3E),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );

    if (croppedFile != null) {
      this.croppedFile = croppedFile;
      initialImageUrl = null;
      notifyListeners();
    }
  }

  Future<String> uploadImageToFirebase() async {
    if (croppedFile == null && pickedFile == null) return '';

    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final String? userId = UID.user;
      final Directory appDir = await getApplicationDocumentsDirectory();
      
      fileName = "$userId.jpg";
      final filePath = "${appDir.path}/$fileName";
      final File file = File(filePath);
      
      final Uint8List fileBytes;
      final cropped = croppedFile;
      if (cropped != null) {
        fileBytes = await cropped.readAsBytes();
      } else {
        fileBytes = await pickedFile!.readAsBytes();
      }
      await file.writeAsBytes(fileBytes);

      final Reference ref = storage.ref().child('$fileName');
      final UploadTask uploadTask = ref.putFile(file);

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String imageUrl = await taskSnapshot.ref.getDownloadURL();
      
      file.delete();
      return imageUrl;
    } catch (e) {
      print('Erro ao enviar a imagem: $e');
      return '';
    }
  }

  Future<void> deleteImage(String? imageName) async {
    if (imageName == null || imageName.isEmpty) return;

    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final Reference ref = storage.ref().child('images/$imageName.jpg');
      await ref.delete();
      print('Imagem excluída com sucesso!');
    } catch (e) {
      print('Erro ao excluir a imagem: $e');
    }
  }

  void resetImage() {
    pickedFile = null;
    croppedFile = null;
    fileName = null;
    initialImageUrl = null;
    notifyListeners();
  }

  void resetCrop() {
    croppedFile = null;
    notifyListeners();
  }
}
