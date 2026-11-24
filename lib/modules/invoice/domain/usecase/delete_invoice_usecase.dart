import 'package:oflite/modules/invoice/data/model/invoice.dart';
import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Apaga o documento e o arquivo do Storage.
class DeleteInvoiceUsecase {
  final InvoiceRepository _repo;

  const DeleteInvoiceUsecase(this._repo);

  Future<Result<void>> call(String budgetId, Invoice invoice) =>
      _repo.deleteInvoice(budgetId, invoice);
}
