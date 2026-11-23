import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/gallery_asset_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/load_gallery_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/pick_proof_attachments_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/gallery_asset_entity.dart'
    show RawMediaFile;
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_limits.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';

/// Seletor de fotos estilo WhatsApp: grade, abas Fotos/Álbuns, até 2 fotos
/// com número da ordem, legenda e enviar com contador.
class ChatMediaPickerViewModel extends ChangeNotifier {
  final LoadGalleryUsecase _gallery;
  final PickProofAttachmentsUsecase _pick;

  ChatMediaPickerViewModel(this._gallery, this._pick);

  final captionController = TextEditingController();

  bool loading = true;
  bool hasPermission = true;
  bool showAlbums = false;
  bool sending = false;

  /// Avisa a View que a 3ª foto foi recusada.
  bool limitHit = false;

  List<GalleryAlbumEntity> albums = [];
  GalleryAlbumEntity? album;
  final List<GalleryAssetEntity> assets = [];
  final List<GalleryAssetEntity> selected = [];

  /// Recortes feitos antes de enviar: id da foto → caminho recortado.
  final Map<String, String> _cropped = {};

  /// Miniatura da última foto selecionada (botão de recorte).
  Uint8List? lastThumb;

  GalleryAssetEntity? get lastSelected =>
      selected.isEmpty ? null : selected.last;

  String? croppedPathOf(GalleryAssetEntity a) => _cropped[a.id];

  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> init() async {
    hasPermission = await _gallery.requestPermission();
    if (!hasPermission) {
      loading = false;
      _notify();
      return;
    }
    albums = await _gallery.albums();
    if (albums.isNotEmpty) await selectAlbum(albums.first);
    loading = false;
    _notify();
  }

  Future<void> openSettings() => _gallery.openSettings();

  void setShowAlbums(bool value) {
    showAlbums = value;
    _notify();
  }

  Future<void> selectAlbum(GalleryAlbumEntity a) async {
    album = a;
    showAlbums = false;
    assets.clear();
    _page = 0;
    _hasMore = true;
    _notify();
    await loadMore();
  }

  Future<void> loadMore() async {
    final a = album;
    if (a == null || !_hasMore || _loadingMore) return;
    _loadingMore = true;
    final page = await _gallery.page(a.id, _page);
    _page++;
    _hasMore = page.isNotEmpty;
    assets.addAll(page);
    _loadingMore = false;
    _notify();
  }

  /// Posição (1, 2) na seleção, ou 0.
  int orderOf(GalleryAssetEntity a) =>
      selected.indexWhere((s) => s.id == a.id) + 1;

  void toggle(GalleryAssetEntity a) {
    limitHit = false;
    final i = selected.indexWhere((s) => s.id == a.id);
    if (i >= 0) {
      selected.removeAt(i);
      _cropped.remove(a.id);
    } else if (selected.length >= PaymentProofLimits.maxImagesPerSend) {
      limitHit = true;
    } else {
      selected.add(a);
    }
    _notify();
    _loadLastThumb();
  }

  Future<void> _loadLastThumb() async {
    final last = lastSelected;
    lastThumb = last == null ? null : await last.thumbnail();
    _notify();
  }

  /// Recorta a última foto selecionada (lápis à esquerda da legenda).
  Future<void> cropLast() async {
    final last = lastSelected;
    if (last == null) return;
    final path = _cropped[last.id] ?? await last.filePath();
    if (path == null) return;
    final out = await _pick.cropPath(
      path,
      title: PaymentProofStrings.cropTitle,
    );
    if (out == null) return;
    _cropped[last.id] = out;
    _notify();
  }

  void consumeLimitHit() => limitHit = false;

  Future<ProofAttachmentValidation> finish() async {
    sending = true;
    _notify();
    final raw = <RawMediaFile>[];
    for (final a in selected) {
      final path = _cropped[a.id] ?? await a.filePath();
      if (path != null) raw.add((path: path, mime: null));
    }
    final v = await _pick.fromRaw(raw);
    sending = false;
    _notify();
    return v;
  }

  @override
  void dispose() {
    _disposed = true;
    captionController.dispose();
    super.dispose();
  }
}
