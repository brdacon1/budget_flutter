import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_media_picker/chat_media_picker_view_model.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_media_picker/components/chat_caption_send_bar.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_media_picker/components/chat_crop_thumb_button.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_media_picker/components/chat_gallery_tile.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Resultado do seletor: anexos validados + legenda.
typedef ChatMediaPickResult = ({
  ProofAttachmentValidation validation,
  String caption,
});

/// Seletor de fotos estilo WhatsApp em modal de 75% da tela (abas
/// Fotos/Álbuns, até 2 fotos, recorte, legenda e enviar com contador).
class ChatMediaPickerView extends StatefulWidget {
  const ChatMediaPickerView({super.key});

  static Future<ChatMediaPickResult?> show(BuildContext context) =>
      showModalBottomSheet<ChatMediaPickResult>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: transparentColor,
        builder:
            (sheet) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheet).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheet).size.height * 0.75,
                child: const ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  child: ChatMediaPickerView(),
                ),
              ),
            ),
      );

  @override
  State<ChatMediaPickerView> createState() => _ChatMediaPickerViewState();
}

class _ChatMediaPickerViewState extends State<ChatMediaPickerView> {
  final _vm = getIt<ChatMediaPickerViewModel>();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
    _vm.init();
  }

  void _onChanged() {
    if (_vm.limitHit && mounted) {
      _vm.consumeLimitHit();
      getIt<DisplayAlertRepository>().notificationWarning(
        context,
        PaymentProofStrings.warningTitle,
        PaymentProofStrings.maxPhotos,
      );
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final v = await _vm.finish();
    if (!mounted) return;
    Navigator.pop(context, (
      validation: v,
      caption: _vm.captionController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        primary: false,
        backgroundColor: bgColor,
        foregroundColor: whiteColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: AnimatedBuilder(
          animation: _vm,
          builder: (_, __) => _Tabs(
            showAlbums: _vm.showAlbums,
            onChanged: _vm.setShowAlbums,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (context, _) {
          if (_vm.loading) {
            return const Center(
              child: CircularProgressIndicator(color: loadingIndicatorColor),
            );
          }
          if (!_vm.hasPermission) return _permission();
          return Column(
            children: [
              Expanded(child: _vm.showAlbums ? _albums() : _grid()),
              if (_vm.selected.isNotEmpty)
                ChatCaptionSendBar(
                  controller: _vm.captionController,
                  count: _vm.selected.length,
                  sending: _vm.sending,
                  onSend: _send,
                  leading: ChatCropThumbButton(
                    image: _cropImageOf(),
                    onTap: _vm.cropLast,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  ImageProvider? _cropImageOf() {
    final last = _vm.lastSelected;
    if (last == null) return null;
    final cropped = _vm.croppedPathOf(last);
    if (cropped != null) return FileImage(File(cropped));
    return _vm.lastThumb == null ? null : MemoryImage(_vm.lastThumb!);
  }

  Widget _permission() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library_outlined, size: 56, color: emptyStateIconColor),
          const SizedBox(height: 12),
          Text(
            PaymentProofStrings.galleryPermission,
            textAlign: TextAlign.center,
            style: const TextStyle(color: whiteColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _vm.openSettings,
            child: Text(PaymentProofStrings.openSettings),
          ),
        ],
      ),
    ),
  );

  Widget _grid() {
    if (_vm.assets.isEmpty) {
      return Center(
        child: Text(
          PaymentProofStrings.emptyGallery,
          style: const TextStyle(color: emptyTextColor),
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 600) _vm.loadMore();
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: _vm.assets.length,
        itemBuilder: (_, i) {
          final a = _vm.assets[i];
          return ChatGalleryTile(
            key: ValueKey(a.id),
            asset: a,
            order: _vm.orderOf(a),
            onTap: () => _vm.toggle(a),
          );
        },
      ),
    );
  }

  Widget _albums() => ListView.separated(
    itemCount: _vm.albums.length,
    separatorBuilder: (_, __) => const Divider(height: 1, color: cardBorderColor),
    itemBuilder: (_, i) {
      final a = _vm.albums[i];
      return ListTile(
        leading: const Icon(Icons.photo_album_outlined, color: mutedTextColor),
        title: Text(a.name, style: const TextStyle(color: whiteColor)),
        trailing: Text(
          '${a.count}',
          style: const TextStyle(color: mutedTextColor),
        ),
        selected: a.id == _vm.album?.id,
        onTap: () => _vm.selectAlbum(a),
      );
    },
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.showAlbums, required this.onChanged});

  final bool showAlbums;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool active, bool value) => GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? secondaryColor : transparentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? whiteColor : mutedTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cartBarColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab(PaymentProofStrings.attachPhotos, !showAlbums, false),
          tab(PaymentProofStrings.albums, showAlbums, true),
        ],
      ),
    );
  }
}
