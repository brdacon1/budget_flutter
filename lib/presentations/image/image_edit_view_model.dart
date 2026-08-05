import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oflite/models/global_uid_user.dart' as UID;

class ImageEditViewModel extends ChangeNotifier {
  XFile? pickedFile;
  CroppedFile? croppedFile;
  String? fileName;

  bool get hasImage => croppedFile != null || pickedFile != null;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      this.pickedFile = pickedFile;
      croppedFile = null;
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
      
      final fileToUpload = croppedFile ?? pickedFile;
      await file.writeAsBytes(await fileToUpload!.readAsBytes());

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

  void resetImage() {
    pickedFile = null;
    croppedFile = null;
    fileName = null;
    notifyListeners();
  }

  void resetCrop() {
    croppedFile = null;
    notifyListeners();
  }
}
