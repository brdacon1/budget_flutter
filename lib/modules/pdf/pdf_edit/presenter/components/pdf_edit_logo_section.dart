import 'dart:typed_data';
import 'package:flutter/material.dart';

class PdfEditLogoSection extends StatelessWidget {
  final Uint8List? fileContent;
  final bool loading;
  final bool hasError;
  final bool autoRenewing;
  final VoidCallback onEditLogo;
  final VoidCallback onOpenSubscription;

  const PdfEditLogoSection({
    super.key,
    required this.fileContent,
    required this.loading,
    required this.hasError,
    required this.autoRenewing,
    required this.onEditLogo,
    required this.onOpenSubscription,
  });

  Widget _image(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final constraints = BoxConstraints(
      maxWidth: 0.8 * screenWidth,
      maxHeight: 0.7 * screenHeight,
    );
    if (fileContent != null && fileContent!.isNotEmpty) {
      return ConstrainedBox(
        constraints: constraints,
        child: Image.memory(fileContent!, fit: BoxFit.contain),
      );
    }
    return ConstrainedBox(
      constraints: constraints,
      child: const Icon(Icons.image, size: 100),
    );
  }

  Widget _imageCard(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              color: Colors.white,
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: _image(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Sem imagem disponível',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Toque para incluir nova imagem',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    return Column(
      children: [
        SizedBox(height: he * 0.02),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (hasError)
          const Center(child: Text('Erro ao carregar a imagem'))
        else
          GestureDetector(
            onTap: autoRenewing ? onEditLogo : onOpenSubscription,
            child: fileContent != null ? _imageCard(context) : _emptyLabel(context),
          ),
      ],
    );
  }
}
