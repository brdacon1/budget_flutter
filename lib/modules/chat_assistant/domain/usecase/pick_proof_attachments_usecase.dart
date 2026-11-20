import 'package:oflite/modules/chat_assistant/domain/entity/gallery_asset_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_media_repository.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';

/// Câmera, documento ou fotos da galeria → anexos validados (R2, R6).
class PickProofAttachmentsUsecase {
  final ChatMediaRepository _media;
  final ValidateProofAttachmentsUsecase _validate;

  const PickProofAttachmentsUsecase(this._media, this._validate);

  Future<ProofAttachmentValidation?> camera() async {
    final f = await _media.takePhoto();
    return f == null ? null : _validate([f]);
  }

  Future<ProofAttachmentValidation?> document() async {
    final f = await _media.pickPdf();
    return f == null ? null : _validate([f]);
  }

  /// Câmera + fotos ao abrir o chat (melhoria 7).
  Future<bool> requestPermissions() => _media.requestMediaPermissions();

  /// Recorta uma imagem já escolhida. PDF ou cancelado → o mesmo anexo.
  Future<ProofAttachment> crop(ProofAttachment file, {required String title}) async {
    if (file.isPdf) return file;
    final path = await _media.cropImage(file.path, title: title);
    if (path == null) return file;
    return ProofAttachment(
      path: path,
      name: file.name,
      type: file.type,
      size: file.size,
    );
  }

  /// Recorta um caminho local (seleção da galeria antes de enviar).
  Future<String?> cropPath(String path, {required String title}) =>
      _media.cropImage(path, title: title);

  Future<ProofAttachmentValidation> fromRaw(List<RawMediaFile> raw) =>
      _validate(raw);
}
