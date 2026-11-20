import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Mostra um comprovante: imagem em tela cheia (pinch-zoom) ou PDF no
/// visualizador de PDF do app. Aceita arquivo local ([localPath]) ou
/// URL do Storage ([url]). Sem VM: só exibe (modal/tela simples, §19).
class PaymentProofViewerView extends StatelessWidget {
  const PaymentProofViewerView({
    super.key,
    required this.title,
    required this.type,
    this.localPath,
    this.url,
  });

  final String title;
  final PaymentProofType type;
  final String? localPath;
  final String? url;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required PaymentProofType type,
    String? localPath,
    String? url,
  }) => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (_) => PaymentProofViewerView(
            title: title,
            type: type,
            localPath: localPath,
            url: url,
          ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isPdf = type == PaymentProofType.pdf;
    return Scaffold(
      backgroundColor: isPdf ? bgColor : blackColor,
      appBar: AppBar(
        backgroundColor: isPdf ? bgColor : blackColor,
        foregroundColor: whiteColor,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: isPdf ? _pdf() : _image(),
    );
  }

  Widget _pdf() {
    if (localPath != null) return SfPdfViewer.file(File(localPath!));
    return SfPdfViewer.network(url ?? '');
  }

  Widget _image() {
    final img =
        localPath != null
            ? Image.file(File(localPath!), fit: BoxFit.contain)
            : Image.network(
              url ?? '',
              fit: BoxFit.contain,
              loadingBuilder:
                  (_, child, progress) =>
                      progress == null
                          ? child
                          : const Center(
                            child: CircularProgressIndicator(
                              color: loadingIndicatorColor,
                            ),
                          ),
              errorBuilder:
                  (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: emptyStateIconColor,
                    size: 64,
                  ),
            );
    return Center(
      child: InteractiveViewer(minScale: 1, maxScale: 5, child: img),
    );
  }
}
