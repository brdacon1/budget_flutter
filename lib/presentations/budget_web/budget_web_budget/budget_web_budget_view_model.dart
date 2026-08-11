import 'package:flutter/material.dart';
import 'package:oflite/common/strings/budget_web_strings.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/models/observation_pdf.dart';
import 'package:oflite/models/owner_pdf.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/loading_event.dart';
import 'package:oflite/services/web_budget_service.dart';

/// Estado do orçamento liberado no fluxo Web.
///
/// Carrega, uma única vez, o orçamento (CustomerInfo), os itens, os dados do
/// titular (OwnerPdf) e as observações — tudo via [WebBudgetService] (REST
/// + token provisório do Firebase). Centraliza totais e a ação de
/// aprovação/reprovação, reutilizando o campo `STATUS` (regra de negócio
/// existente) — nenhuma regra paralela.
class BudgetWebBudgetViewModel extends ChangeNotifier {
  BudgetWebBudgetViewModel({
    required this.ownerUid,
    required this.enderecoNumero,
    required this.token,
  });

  final String ownerUid;
  final String enderecoNumero;
  final String token;

  final WebBudgetService _service = WebBudgetService();
  final DisplayAlert _displayAlert = DisplayAlert();
  final LoadingEvent _loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  CustomerInfo? _budget;
  CustomerInfo? get budget => _budget;

  List<ItemsBudget> _items = const [];
  List<ItemsBudget> get items => _items;

  OwnerPdf? _owner;
  OwnerPdf? get owner => _owner;

  List<ObservationPdf> _observations = const [];
  List<ObservationPdf> get observations => _observations;

  double totalProducts = 0;
  double totalServices = 0;
  double totalBudget = 0;
  int countProduct = 0;
  int countService = 0;

  bool _disposed = false;
  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> inicialData() async {
    _loading = true;
    _error = null;
    _safeNotify();
    try {
      final budget = await _service.getBudget(
        ownerUid: ownerUid,
        enderecoNumero: enderecoNumero,
        token: token,
      );
      final items = await _service.getItems(
        ownerUid: ownerUid,
        enderecoNumero: enderecoNumero,
        token: token,
      );
      final ownerMap = await _service.getOwnerInfo(
        ownerUid: ownerUid,
        token: token,
      );
      final observations = await _service.getObservations(
        ownerUid: ownerUid,
        enderecoNumero: enderecoNumero,
        token: token,
      );

      _budget = budget;
      _items = items;
      _owner = OwnerPdf.fromJson(ownerMap);
      _observations = observations;
      _calcTotals();
    } on WebBudgetAccessError catch (_) {
      _error = BudgetWebStrings.blockedMessage;
    } catch (_) {
      _error = BudgetWebStrings.blockedMessage;
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  void _calcTotals() {
    totalProducts = 0;
    totalServices = 0;
    totalBudget = 0;
    countProduct = 0;
    countService = 0;
    for (final i in _items) {
      final total = i.TOTAL ?? 0;
      if (i.CATEGORIA == 'Produtos') {
        totalProducts += total;
        countProduct++;
      } else if (i.CATEGORIA == 'Serviços') {
        totalServices += total;
        countService++;
      }
      totalBudget += total;
    }
  }

  /// Aprova/reprova reutilizando o campo `STATUS` do orçamento (mesmos
  /// valores usados pelo app mobile). Não cria regra paralela.
  Future<void> updateStatus(BuildContext context, String status) async {
    _loadingEvent.alertLoading(context);
    try {
      await _service.updateStatus(
        ownerUid: ownerUid,
        enderecoNumero: enderecoNumero,
        token: token,
        status: status,
      );
      if (context.mounted) _loadingEvent.closeLoading(context);
      // Atualiza localmente (imutável onde possível; CustomerInfo é legado).
      _budget?.status = status;
      _safeNotify();
      if (context.mounted) {
        await _displayAlert.notification(
          context,
          BudgetWebStrings.statusApproved,
          BudgetWebStrings.approvalSuccess,
        );
      }
    } catch (_) {
      if (context.mounted) _loadingEvent.closeLoading(context);
      if (context.mounted) {
        await _displayAlert.notificationError(
          context,
          BudgetWebStrings.blockedTitle,
          BudgetWebStrings.approvalError,
        );
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
