import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_limits.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/modules/payment_proof/domain/repository/payment_proof_repository.dart';

/// Motivo de recusa de um anexo.
enum ProofAttachmentIssue { empty, invalidType, tooBig, mixed }

/// Resultado da validação: arquivos aceitos e avisos.
class ProofAttachmentValidation {
  final List<ProofAttachment> files;
  final ProofAttachmentIssue? issue;

  /// `true` quando havia mais de 2 imagens e só as 2 primeiras ficaram.
  final bool trimmed;

  const ProofAttachmentValidation(this.files, {this.issue, this.trimmed = false});

  bool get isValid => issue == null && files.isNotEmpty;
}

/// R2 e R6: até 2 imagens OU 1 PDF; tipos aceitos; PDF até 10 MB.
/// Imagens não têm teto aqui: são comprimidas para no máximo 8 MB no envio.
class ValidateProofAttachmentsUsecase {
  final PaymentProofRepository _repo;

  const ValidateProofAttachmentsUsecase(this._repo);

  /// Descobre o tipo pela extensão (ou mime). `null` = não aceito.
  static PaymentProofType? typeOf(String path, {String? mime}) {
    final m = mime?.toLowerCase() ?? '';
    if (m == 'application/pdf') return PaymentProofType.pdf;
    if (m.startsWith('image/')) return PaymentProofType.image;
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'pdf') return PaymentProofType.pdf;
    if (PaymentProofLimits.imageExtensions.contains(ext)) {
      return PaymentProofType.image;
    }
    return null;
  }

  /// Monta os anexos a partir de caminhos locais e valida.
  Future<ProofAttachmentValidation> call(
    List<({String path, String? mime})> raw,
  ) async {
    if (raw.isEmpty) {
      return const ProofAttachmentValidation([], issue: ProofAttachmentIssue.empty);
    }
    final files = <ProofAttachment>[];
    for (final r in raw) {
      final type = typeOf(r.path, mime: r.mime);
      if (type == null) {
        return const ProofAttachmentValidation(
          [],
          issue: ProofAttachmentIssue.invalidType,
        );
      }
      final size = await _repo.fileSize(r.path);
      if (type == PaymentProofType.pdf &&
          size > PaymentProofLimits.maxFileBytes) {
        return const ProofAttachmentValidation(
          [],
          issue: ProofAttachmentIssue.tooBig,
        );
      }
      files.add(
        ProofAttachment(
          path: r.path,
          name: r.path.split('/').last,
          type: type,
          size: size,
        ),
      );
    }
    final pdfs = files.where((f) => f.isPdf).toList();
    if (pdfs.isNotEmpty) {
      if (files.length > 1) {
        return ProofAttachmentValidation(
          [pdfs.first],
          issue: files.length == pdfs.length ? null : ProofAttachmentIssue.mixed,
          trimmed: files.length == pdfs.length,
        );
      }
      return ProofAttachmentValidation(files);
    }
    if (files.length > PaymentProofLimits.maxImagesPerSend) {
      return ProofAttachmentValidation(
        files.take(PaymentProofLimits.maxImagesPerSend).toList(),
        trimmed: true,
      );
    }
    return ProofAttachmentValidation(files);
  }
}
