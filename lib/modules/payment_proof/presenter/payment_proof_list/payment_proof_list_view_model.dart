import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/delete_payment_proof_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/list_payment_proofs_usecase.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Lista de comprovantes de um orçamento (§15.7).
class PaymentProofListViewModel extends ChangeNotifier {
  final CustomerInfo item;
  final ListPaymentProofsUsecase _list;
  final DeletePaymentProofUsecase _delete;
  final ConvertCoinRepository moneyConvert;

  PaymentProofListViewModel({
    required this.item,
    ListPaymentProofsUsecase? list,
    DeletePaymentProofUsecase? delete,
    ConvertCoinRepository? convertCoin,
  }) : _list = list ?? getIt<ListPaymentProofsUsecase>(),
       _delete = delete ?? getIt<DeletePaymentProofUsecase>(),
       moneyConvert = convertCoin ?? getIt<ConvertCoinRepository>();

  List<PaymentProof> proofs = [];
  double total = 0;
  bool loading = true;
  bool loadError = false;

  late final Command1<void, PaymentProof> deleteCommand = Command1(_remove);

  String get _budgetId => item.id ?? '';

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final res = await _list(_budgetId);
    switch (res) {
      case Ok(:final value):
        proofs = value.proofs;
        total = value.total;
        loadError = false;
      case Error():
        loadError = true;
    }
    loading = false;
    notifyListeners();
  }

  Future<Result<void>> _remove(PaymentProof proof) async {
    final res = await _delete(_budgetId, proof);
    if (res is Ok) {
      proofs = proofs.where((p) => p.id != proof.id).toList();
      total = ListPaymentProofsUsecase.totalOf(proofs);
      notifyListeners();
    }
    return res;
  }

  String dateTimeOf(PaymentProof p) {
    final local = p.createdAt.toLocal();
    return PaymentProofStrings.dateTime(
      DateFormat('dd/MM/yyyy').format(local),
      DateFormat('HH:mm').format(local),
    );
  }

  String get totalText => moneyConvert.convertFromDouble(total);

  String valueOf(PaymentProof p) =>
      p.value == null
          ? PaymentProofStrings.noValue
          : moneyConvert.convertFromDouble(p.value!);
}
