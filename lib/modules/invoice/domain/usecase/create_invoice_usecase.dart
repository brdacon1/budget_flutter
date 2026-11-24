import 'package:oflite/modules/invoice/data/model/invoice.dart';
import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_limits.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class InvoiceNameRequired implements Exception {}

class InvoiceValueRequired implements Exception {}

class InvoiceLimitReached implements Exception {}

/// Grava as notas fiscais de um envio. Nome e valor > 0 são obrigatórios;
/// máx. 15 por orçamento. 2 imagens = 2 documentos (` (1)`/` (2)`). O ID é o
/// timestamp em ms; `CRIADOEM` guarda data+hora.
class CreateInvoiceUsecase {
  final InvoiceRepository _repo;
  final DateTime Function() _now;

  CreateInvoiceUsecase(this._repo, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  Future<Result<List<Invoice>>> call({
    required String budgetId,
    required List<ProofAttachment> files,
    required String name,
    required double? value,
    PaymentProofOrigin origin = PaymentProofOrigin.chat,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return Result.error(InvoiceNameRequired());
    if (value == null || value <= 0) {
      return Result.error(InvoiceValueRequired());
    }
    if (files.isEmpty) return Result.error(Exception('no files'));

    final count = await _repo.countInvoices(budgetId);
    if (count case Error(:final error)) return Result.error(error);
    if ((count as Ok<int>).value + files.length >
        PaymentProofLimits.maxPerBudget) {
      return Result.error(InvoiceLimitReached());
    }

    final saved = <Invoice>[];
    for (var i = 0; i < files.length; i++) {
      final createdAt = _now();
      final res = await _repo.saveInvoice(
        budgetId: budgetId,
        id: (createdAt.millisecondsSinceEpoch + i).toString(),
        localPath: files[i].path,
        type: files[i].type,
        name: files.length > 1 ? '$cleanName (${i + 1})' : cleanName,
        value: value,
        createdAt: createdAt,
        origin: origin,
      );
      switch (res) {
        case Ok(:final value):
          saved.add(value);
        case Error(:final error):
          for (final s in saved) {
            await _repo.deleteInvoice(budgetId, s);
          }
          return Result.error(error);
      }
    }
    return Result.ok(saved);
  }
}
