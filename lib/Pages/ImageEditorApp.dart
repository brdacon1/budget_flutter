import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oflite/Models/Db.dart';
import 'package:oflite/Pages/pg_editPDF.dart';
import 'package:path_provider/path_provider.dart';
import '../Objetos/Owner.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import '../Services/loading_event.dart';
import '../constants.dart';


class CutPicturePage extends StatefulWidget {
  final String title;
  final Owner owner;
  const CutPicturePage({
    Key? key,
    required this.title,
    required this.owner,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<CutPicturePage> {
  XFile? _pickedFile;
  CroppedFile? _croppedFile;
  String? fileName;
  final alertDisplayLoading = LoadingEvent();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !kIsWeb ? AppBar(title: Text(widget.title),
      backgroundColor: bgColor,) : null,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
              child: Text(
                widget.title,
                style: Theme.of(context)
                    .textTheme
                    .displayMedium!
                    .copyWith(color: Theme.of(context).highlightColor),
              ),
            ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_croppedFile != null || _pickedFile != null) {
      return _imageCard();
    } else {
      return _uploaderCard();
    }
  }

  Widget _imageCard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: kIsWeb ? 24.0 : 16.0),
            child: Card(
              color: Colors.white,
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
                child: _image(),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          _menu(),
        ],
      ),
    );
  }

  Widget _image() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if (_croppedFile != null) {
      final path = _croppedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: kIsWeb ? Image.network(path) : Image.file(File(path)),
      );
    } else if (_pickedFile != null) {
      final path = _pickedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: kIsWeb ? Image.network(path) : Image.file(File(path)),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _menu() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () async {
            alertDisplayLoading.alertLoading(context);
            var db = Db();
            var localOwner = Owner();
            try {

              if(widget.owner.fotoId!.isNotEmpty &&  widget.owner.logoName!.isNotEmpty)
              {
                await deleteImage(widget.owner.logoName);
              }
              await _uploadImageToFirebase().then((value) => {
                if(extractTokenFromUrl(value)!.isNotEmpty){
                  localOwner.bairro = widget.owner.bairro,
                  localOwner.fotoId = extractTokenFromUrl(value),
                  widget.owner.fotoId = extractTokenFromUrl(value),
                  localOwner.city = widget.owner.city,
                  localOwner.rua = widget.owner.rua,
                  localOwner.cep = widget.owner.cep,
                  localOwner.email = widget.owner.email,
                  localOwner.fone = widget.owner.fone,
                  localOwner.cnpj = widget.owner.cnpj,
                  localOwner.empresa = widget.owner.empresa,
                  localOwner.logoName = fileName,
                  widget.owner.logoName = fileName,
                  db.savePDF(localOwner),
                  alertDisplayLoading.closeLoading(context),
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const PgEditPDF()),
                    ModalRoute.withName('/pg-pdf-config'),
                  ),
              }
              });

            } catch (e){
              alertDisplayLoading.closeLoading(context);
            }

          },
          backgroundColor: Colors.green,
          tooltip: 'Save',
          child: const Icon(Icons.save),
        ),
        if (_croppedFile == null)
        Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: FloatingActionButton(
              onPressed: () {
                _cropImage();
              },
              backgroundColor: buttonColor,
              tooltip: 'Crop',
              child: const Icon(Icons.crop),
            ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: FloatingActionButton(
            onPressed: () {
              _clear();
            },
            backgroundColor: Colors.redAccent,
            tooltip: 'Delete',
            child: const Icon(Icons.delete),
          ),
        ),
      ],
    );
  }

  Widget _uploaderCard() {
    return Center(
      child: Card(
        color: Colors.white,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: SizedBox(
          width: kIsWeb ? 380.0 : 320.0,
          height: 300.0,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DottedBorder(
                    radius: const Radius.circular(12.0),
                    borderType: BorderType.RRect,
                    dashPattern: const [8, 4],
                    color: bgColor,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: bgColor,
                            size: 80.0,
                          ),
                          SizedBox(height: 24.0),
                          Text(
                            'Selecione uma imagem',
                            style: TextStyle(color: bgColor)
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child:  TextButton(
                  onPressed: (){
                    _uploadImage();
                  },
                  style: TextButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 70),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0)
                      )
                  ),
                  child: Text("Selecionar foto",style: GoogleFonts.heebo(
                    color: Colors.black,
                    letterSpacing: 0.5,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _uploadImageToFirebase() async {
    if (_croppedFile != null) {
      try {
        final FirebaseStorage storage = FirebaseStorage.instance;
        final String? fileName = UID.USER;
        final Directory appDir = await getApplicationDocumentsDirectory();
        this.fileName = "$fileName.jpg";
        final filePath = "${appDir.path}/$fileName.jpg";
        final File file = File(filePath);
        await file.writeAsBytes(await _croppedFile!.readAsBytes());

        final Reference ref = storage.ref().child('$fileName.jpg');
        final UploadTask uploadTask = ref.putFile(file);

        final TaskSnapshot taskSnapshot = await uploadTask;
        final String imageUrl = await taskSnapshot.ref.getDownloadURL();
        print('Imagem enviada com sucesso! URL da imagem: $imageUrl');

        // Delete the temporary file after uploading.
        file.delete();

        return imageUrl;
      } catch (e) {
        print('Erro ao enviar a imagem: $e');
        return '';
      }
    }
    else{
      final FirebaseStorage storage = FirebaseStorage.instance;
      final String? fileName = UID.USER;
      final Directory appDir = await getApplicationDocumentsDirectory();
      this.fileName = "$fileName.jpg";
      final filePath = "${appDir.path}/$fileName.jpg";
      final File file = File(filePath);
      await file.writeAsBytes(await _pickedFile!.readAsBytes());

      final Reference ref = storage.ref().child('$fileName.jpg');
      final UploadTask uploadTask = ref.putFile(file);

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String imageUrl = await taskSnapshot.ref.getDownloadURL();
      print('Imagem enviada com sucesso! URL da imagem: $imageUrl');

      // Delete the temporary file after uploading.
      file.delete();

      return imageUrl;
    }
  }

  String? extractTokenFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      Map<String, String> queryParameters = uri.queryParameters;
      return queryParameters['token'];
    } catch (e) {
      print('Erro ao extrair o token da URL: $e');
      return null;
    }
  }

  Future<void> deleteImage(String? imageName) async {
    try {
      // Inicialize a instância do Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;

      // Crie uma referência para a imagem que você deseja excluir
      Reference reference = storage.ref().child('images/$imageName.jpg');

      // Exclua a imagem
      await reference.delete();

      print('Imagem excluída com sucesso!');
    } catch (e) {
      print('Erro ao excluir a imagem: $e');
    }
  }

  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cortar imagem',
              toolbarColor: bgColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: const CroppieBoundary(
              width: 520,
              height: 520,
            ),
            viewPort:
            const CroppieViewPort(width: 480, height: 480, type: 'circle'),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _croppedFile = croppedFile;
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
      });
    }
  }

  void _clear() {
    setState(() {
      _pickedFile = null;
      _croppedFile = null;
    });
  }
}