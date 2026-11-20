import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class PaymentProofRepository {
  Future<Result<List<PaymentProof>>> fetchProofs(String budgetId);

  Future<Result<int>> countProofs(String budgetId);

  /// Comprime (imagem), envia o arquivo e grava o documento. Se a gravação
  /// falhar, apaga o arquivo enviado (sem órfãos).
  Future<Result<PaymentProof>> saveProof({
    required String budgetId,
    required String id,
    required String localPath,
    required PaymentProofType type,
    required String name,
    double? value,
    String? comment,
    required DateTime createdAt,
    required PaymentProofOrigin origin,
  });

  Future<Result<void>> deleteProof(String budgetId, PaymentProof proof);

  /// Tamanho do arquivo local, em bytes.
  Future<int> fileSize(String path);
}
