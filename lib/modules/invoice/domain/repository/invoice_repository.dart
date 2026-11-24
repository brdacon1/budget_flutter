import 'package:oflite/modules/invoice/data/model/invoice.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class InvoiceRepository {
  Future<Result<List<Invoice>>> fetchInvoices(String budgetId);

  Future<Result<int>> countInvoices(String budgetId);

  /// Comprime (imagem), envia o arquivo e grava o documento. Se a gravação
  /// falhar, apaga o arquivo enviado (sem órfãos).
  Future<Result<Invoice>> saveInvoice({
    required String budgetId,
    required String id,
    required String localPath,
    required PaymentProofType type,
    required String name,
    required double value,
    required DateTime createdAt,
    required PaymentProofOrigin origin,
  });

  Future<Result<void>> deleteInvoice(String budgetId, Invoice invoice);
}
