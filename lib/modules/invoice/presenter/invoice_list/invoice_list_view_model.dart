import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/invoice/data/model/invoice.dart';
import 'package:oflite/modules/invoice/domain/usecase/delete_invoice_usecase.dart';
import 'package:oflite/modules/invoice/domain/usecase/list_invoices_usecase.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Lista de notas fiscais de um orçamento (§15.7).
class InvoiceListViewModel extends ChangeNotifier {
  final CustomerInfo item;
  final ListInvoicesUsecase _list;
  final DeleteInvoiceUsecase _delete;
  final ConvertCoinRepository moneyConvert;

  InvoiceListViewModel({
    required this.item,
    ListInvoicesUsecase? list,
    DeleteInvoiceUsecase? delete,
    ConvertCoinRepository? convertCoin,
  }) : _list = list ?? getIt<ListInvoicesUsecase>(),
       _delete = delete ?? getIt<DeleteInvoiceUsecase>(),
       moneyConvert = convertCoin ?? getIt<ConvertCoinRepository>();

  List<Invoice> invoices = [];
  double total = 0;
  bool loading = true;
  bool loadError = false;

  late final Command1<void, Invoice> deleteCommand = Command1(_remove);

  String get _budgetId => item.id ?? '';

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final res = await _list(_budgetId);
    switch (res) {
      case Ok(:final value):
        invoices = value.invoices;
        total = value.total;
        loadError = false;
      case Error():
        loadError = true;
    }
    loading = false;
    notifyListeners();
  }

  Future<Result<void>> _remove(Invoice proof) async {
    final res = await _delete(_budgetId, proof);
    if (res is Ok) {
      invoices = invoices.where((p) => p.id != proof.id).toList();
      total = ListInvoicesUsecase.totalOf(invoices);
      notifyListeners();
    }
    return res;
  }

  String dateTimeOf(Invoice p) {
    final local = p.createdAt.toLocal();
    return PaymentProofStrings.dateTime(
      DateFormat('dd/MM/yyyy').format(local),
      DateFormat('HH:mm').format(local),
    );
  }

  String get totalText => moneyConvert.convertFromDouble(total);

  String valueOf(Invoice p) => moneyConvert.convertFromDouble(p.value);
}
