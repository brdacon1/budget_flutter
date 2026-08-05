import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oflite/models/owner_pdf.dart';
import 'package:oflite/services/http_request.dart';
import 'package:path_provider/path_provider.dart';

class ImageEditViewModel extends ChangeNotifier {
  final HttpRequest _httpRequest = HttpRequest();

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
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar Imagem',
          toolbarColor: const Color(0xFF2A2D3E),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Recortar Imagem',
        ),
        WebUiSettings(
          context: null,
        ),
      ],
    );

    if (croppedFile != null) {
      this.croppedFile = croppedFile;
      notifyListeners();
    }
  }

  Future<void> uploadImage(OwnerPdf owner) async {
    if (croppedFile == null && pickedFile == null) return;

    final file = File(croppedFile?.path ?? pickedFile!.path);
    fileName = file.path.split('/').last;

    await _httpRequest.uploadPictureFirebase(
      file,
      owner.UID!,
      fileName!,
      'logo',
    );
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
