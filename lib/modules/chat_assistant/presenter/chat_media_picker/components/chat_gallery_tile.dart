import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/gallery_asset_entity.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Miniatura da galeria com a bolinha de seleção (número da ordem).
class ChatGalleryTile extends StatefulWidget {
  const ChatGalleryTile({
    super.key,
    required this.asset,
    required this.order,
    required this.onTap,
  });

  final GalleryAssetEntity asset;

  /// 0 = não selecionada.
  final int order;
  final VoidCallback onTap;

  @override
  State<ChatGalleryTile> createState() => _ChatGalleryTileState();
}

class _ChatGalleryTileState extends State<ChatGalleryTile> {
  late final Future<Uint8List?> _thumb = widget.asset.thumbnail();

  @override
  Widget build(BuildContext context) {
    final selected = widget.order > 0;
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: _thumb,
            builder:
                (_, snap) =>
                    snap.data == null
                        ? const ColoredBox(color: secondaryColor)
                        : Image.memory(snap.data!, fit: BoxFit.cover),
          ),
          if (selected) ColoredBox(color: whiteColor.withValues(alpha: 0.25)),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? cartAccentColor : blackColor.withValues(alpha: 0.2),
                border: Border.all(color: whiteColor, width: 2),
              ),
              child:
                  selected
                      ? Text(
                        '${widget.order}',
                        style: const TextStyle(
                          color: whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      )
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}
