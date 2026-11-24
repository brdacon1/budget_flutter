import 'package:oflite/modules/invoice/data/model/invoice.dart';
import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

typedef InvoiceList = ({List<Invoice> invoices, double total});

/// Notas do orçamento, mais recente primeiro, com o total a cobrar do cliente
/// (a soma é regra de negócio: fica aqui, não no VM).
class ListInvoicesUsecase {
  final InvoiceRepository _repo;

  const ListInvoicesUsecase(this._repo);

  static double totalOf(Iterable<Invoice> invoices) =>
      invoices.fold(0.0, (sum, i) => sum + i.value);

  Future<Result<InvoiceList>> call(String budgetId) async {
    final res = await _repo.fetchInvoices(budgetId);
    return switch (res) {
      Ok(:final value) => Result.ok((
        invoices: [...value]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        total: totalOf(value),
      )),
      Error(:final error) => Result.error(error),
    };
  }
}
