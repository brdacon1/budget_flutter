import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Conteúdo da bolha do usuário com 1–2 imagens ou 1 PDF (estilo WhatsApp).
/// Toque abre o arquivo em tela cheia / no visualizador de PDF.
class ChatAttachmentBubble extends StatelessWidget {
  const ChatAttachmentBubble({super.key, required this.payload, this.onOpen});

  final Map<String, dynamic> payload;
  final void Function(ProofAttachment file)? onOpen;

  List<ProofAttachment> get _files => [
    for (final f in (payload['files'] as List? ?? const []))
      ProofAttachment.fromPayload(Map<String, dynamic>.from(f as Map)),
  ];

  @override
  Widget build(BuildContext context) {
    final files = _files;
    if (files.isEmpty) return const SizedBox.shrink();
    if (files.first.isPdf) return _PdfTile(file: files.first, onOpen: onOpen);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        spacing: 6,
        children: [
          for (final f in files)
            GestureDetector(
              onTap: onOpen == null ? null : () => onOpen!(f),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(f.path),
                  width: files.length == 1 ? 220 : 120,
                  height: files.length == 1 ? 220 : 120,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => const SizedBox(
                        width: 120,
                        height: 120,
                        child: Icon(Icons.broken_image, color: mutedTextColor),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PdfTile extends StatelessWidget {
  const _PdfTile({required this.file, this.onOpen});

  final ProofAttachment file;
  final void Function(ProofAttachment file)? onOpen;

  @override
  Widget build(BuildContext context) {
    final kb = (file.size / 1024).ceil();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: blackColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen == null ? null : () => onOpen!(file),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf, color: statusRejectedColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: whiteColor),
                      ),
                      Text(
                        ChatAssistantStrings.pdfSizeLabel(kb),
                        style: const TextStyle(
                          color: mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
