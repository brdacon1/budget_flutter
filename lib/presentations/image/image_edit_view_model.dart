import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oflite/models/global_uid_user.dart' as UID;

class ImageEditViewModel extends ChangeNotifier {
  XFile? pickedFile;
  CroppedFile? croppedFile;
  String? fileName;
  String? initialImageUrl;

  bool get hasImage =>
      croppedFile != null || pickedFile != null || initialImageUrl != null;

  void loadInitialImage(String? fotoId, String? logoName) {
    if (fotoId == null || fotoId.isEmpty) return;
    if (logoName == null || logoName.isEmpty) return;

    initialImageUrl =
        'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/${Uri.encodeComponent(logoName)}?alt=media&token=$fotoId';
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
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile!.path,
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
