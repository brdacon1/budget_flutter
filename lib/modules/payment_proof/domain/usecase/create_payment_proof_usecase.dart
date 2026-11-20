import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_limits.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/modules/payment_proof/domain/repository/payment_proof_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PaymentProofNameRequired implements Exception {}

class PaymentProofLimitReached implements Exception {}

class PaymentProofValueRequired implements Exception {}

/// Grava os comprovantes de um envio (R3, R4, R5, R7). Nome e valor > 0
/// são obrigatórios.
///
/// 2 imagens = 2 documentos com o mesmo nome e sufixo ` (1)`/` (2)`.
/// O ID é o timestamp em ms (igual aos recibos), `CRIADOEM` guarda data+hora.
class CreatePaymentProofUsecase {
  final PaymentProofRepository _repo;
  final DateTime Function() _now;

  CreatePaymentProofUsecase(this._repo, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  Future<Result<List<PaymentProof>>> call({
    required String budgetId,
    required List<ProofAttachment> files,
    required String name,
    required double? value,
    String? comment,
    PaymentProofOrigin origin = PaymentProofOrigin.chat,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return Result.error(PaymentProofNameRequired());
    if (value == null || value <= 0) {
      return Result.error(PaymentProofValueRequired());
    }
    if (files.isEmpty) return Result.error(Exception('no files'));

    final count = await _repo.countProofs(budgetId);
    if (count case Error(:final error)) return Result.error(error);
    final existing = (count as Ok<int>).value;
    if (existing + files.length > PaymentProofLimits.maxPerBudget) {
      return Result.error(PaymentProofLimitReached());
    }

    final cleanComment = comment?.trim();
    final saved = <PaymentProof>[];
    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      final createdAt = _now();
      final id = (createdAt.millisecondsSinceEpoch + i).toString();
      final res = await _repo.saveProof(
        budgetId: budgetId,
        id: id,
        localPath: f.path,
        type: f.type,
        name: files.length > 1 ? '$cleanName (${i + 1})' : cleanName,
        value: value,
        comment: (cleanComment?.isEmpty ?? true) ? null : cleanComment,
        createdAt: createdAt,
        origin: origin,
      );
      switch (res) {
        case Ok(:final value):
          saved.add(value);
        case Error(:final error):
          // desfaz os já gravados neste envio
          for (final s in saved) {
            await _repo.deleteProof(budgetId, s);
          }
          return Result.error(error);
      }
    }
    return Result.ok(saved);
  }
}
