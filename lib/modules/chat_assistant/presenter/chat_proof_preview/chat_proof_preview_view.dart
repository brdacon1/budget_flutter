import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_media_picker/components/chat_caption_send_bar.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_media_picker/components/chat_crop_thumb_button.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Resultado da prévia: arquivos (recortados ou não) + legenda.
typedef ChatProofPreviewResult = ({List<ProofAttachment> files, String caption});

/// Prévia antes de enviar (câmera, documento ou compartilhamento):
/// arquivo grande, recorte à esquerda da legenda (estilo WhatsApp) e enviar
/// com contador. `null` se fechar.
class ChatProofPreviewView extends StatefulWidget {
  const ChatProofPreviewView({
    super.key,
    required this.files,
    required this.onCrop,
  });

  final List<ProofAttachment> files;
  final Future<ProofAttachment> Function(ProofAttachment file) onCrop;

  static Future<ChatProofPreviewResult?> show(
    BuildContext context,
    List<ProofAttachment> files, {
    required Future<ProofAttachment> Function(ProofAttachment file) onCrop,
  }) => Navigator.of(context, rootNavigator: true).push<ChatProofPreviewResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ChatProofPreviewView(files: files, onCrop: onCrop),
    ),
  );

  @override
  State<ChatProofPreviewView> createState() => _ChatProofPreviewViewState();
}

class _ChatProofPreviewViewState extends State<ChatProofPreviewView> {
  final _caption = TextEditingController();
  late final List<ProofAttachment> _files = [...widget.files];
  int _page = 0;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _crop() async {
    final cropped = await widget.onCrop(_files[_page]);
    if (!mounted) return;
    setState(() => _files[_page] = cropped);
  }

  @override
  Widget build(BuildContext context) {
    final current = _files[_page];
    return Scaffold(
      backgroundColor: blackColor,
      appBar: AppBar(
        backgroundColor: blackColor,
        foregroundColor: whiteColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              onPageChanged: (i) => setState(() => _page = i),
              children: [for (final f in _files) _pageFor(f)],
            ),
          ),
          ChatCaptionSendBar(
            controller: _caption,
            count: _files.length,
            leading:
                current.isPdf
                    ? null
                    : ChatCropThumbButton(
                      image: FileImage(File(current.path)),
                      onTap: _crop,
                    ),
            onSend:
                () => Navigator.pop(context, (
                  files: _files,
                  caption: _caption.text,
                )),
          ),
        ],
      ),
    );
  }

  Widget _pageFor(ProofAttachment f) {
    if (f.isPdf) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 96, color: statusRejectedColor),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                f.name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: whiteColor),
              ),
            ),
          ],
        ),
      );
    }
    return InteractiveViewer(
      child: Center(
        child: Image.file(
          File(f.path),
          key: ValueKey(f.path),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
