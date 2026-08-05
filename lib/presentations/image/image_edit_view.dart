import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/services/http_request.dart';
import '../../models/owner_pdf.dart';
import '../../Services/loading_event.dart';
import '../../common/constants/constants.dart';
import 'image_edit_view_model.dart';


class ImageEditView extends StatefulWidget {
  final String title;
  final OwnerPdf owner;
  const ImageEditView({
    Key? key,
    required this.title,
    required this.owner,
  }) : super(key: key);

  @override
  State<ImageEditView> createState() => _ImageEditView();
}

class _ImageEditView extends State<ImageEditView> {
  late ImageEditViewModel _viewModel;
  final alertDisplayLoading = LoadingEvent();

  @override
  void initState() {
    super.initState();
    _viewModel = ImageEditViewModel();
    _viewModel.addListener(_onViewModelChanged);
    print('ImageEditView: fotoId=${widget.owner.fotoId}, logoName=${widget.owner.logoName}');
    _viewModel.loadInitialImage(
      widget.owner.fotoId,
      widget.owner.logoName,
    );
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !kIsWeb
          ? AppBar(
              title: Text(widget.title),
              backgroundColor: bgColor,
            )
          : null,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: Theme.of(context).highlightColor),
              ),
            ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_viewModel.hasImage) {
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
    if (_viewModel.croppedFile != null) {
      final path = _viewModel.croppedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: kIsWeb ? Image.network(path) : Image.file(File(path)),
      );
    } else if (_viewModel.pickedFile != null) {
      final path = _viewModel.pickedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: kIsWeb ? Image.network(path) : Image.file(File(path)),
      );
    } else if (_viewModel.initialImageUrl != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: Image.network(
          _viewModel.initialImageUrl!,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            print('ImageEditView: erro ao carregar imagem: $error');
            return const Icon(Icons.error, color: Colors.red, size: 64);
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _menu() {
    if (!_viewModel.hasImage) {
      return FloatingActionButton(
        heroTag: "Upload",
        onPressed: () async {
          await _viewModel.pickImage();
        },
        backgroundColor: buttonColor,
        tooltip: 'Upload',
        child: const Icon(Icons.cloud_upload_outlined),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "Save",
          onPressed: () async {
            alertDisplayLoading.alertLoading(context);
            var db = HttpRequest();
            var localOwner = OwnerPdf();
            try {
              if (widget.owner.fotoId!.isNotEmpty &&
                  widget.owner.logoName!.isNotEmpty) {
                await _viewModel.deleteImage(widget.owner.logoName);
              }

              final imageUrl = await _viewModel.uploadImageToFirebase();

              if (imageUrl.isNotEmpty) {
                localOwner.bairro = widget.owner.bairro;
                localOwner.fotoId = imageUrl;
                widget.owner.fotoId = imageUrl;
                localOwner.city = widget.owner.city;
                localOwner.rua = widget.owner.rua;
                localOwner.cep = widget.owner.cep;
                localOwner.email = widget.owner.email;
                localOwner.fone = widget.owner.fone;
                localOwner.cnpj = widget.owner.cnpj;
                localOwner.empresa = widget.owner.empresa;
                localOwner.logoName = _viewModel.fileName;
                widget.owner.logoName = _viewModel.fileName;

                await db.savePDF(localOwner);

                if (mounted) {
                  alertDisplayLoading.closeLoading(context);
                  Navigator.of(context).pop();
                }
              }
            } catch (e) {
              if (mounted) {
                alertDisplayLoading.closeLoading(context);
              }
            }
          },
          backgroundColor: Colors.green,
          tooltip: 'Save',
          child: const Icon(Icons.save),
        ),
        if (_viewModel.croppedFile == null)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: FloatingActionButton(
              heroTag: "Crop",
              onPressed: () async {
                await _viewModel.cropImage();
              },
              backgroundColor: buttonColor,
              tooltip: 'Crop',
              child: const Icon(Icons.crop),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: FloatingActionButton(
            heroTag: "Delete",
            onPressed: () {
              _viewModel.resetImage();
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: Container(
                    height: 204,
                    width: 204,
                    color: Colors.grey[100],
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.grey,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selecione a imagem para fazer upload',
                style: GoogleFonts.heebo(
                  fontSize: 14,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: TextButton(
                  onPressed: () async {
                    await _viewModel.pickImage();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: Text(
                    "Selecionar foto",
                    style: GoogleFonts.heebo(
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
}
