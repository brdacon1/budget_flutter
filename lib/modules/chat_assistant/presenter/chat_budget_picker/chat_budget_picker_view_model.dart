import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_filter.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Modal de seleção de orçamento do chat: filtro por status + busca por
/// cliente. A filtragem fica no [ListBudgetsUsecase].
class ChatBudgetPickerViewModel extends ChangeNotifier {
  final ListBudgetsUsecase _listBudgets;
  final ConvertCoinRepository _coin;

  ChatBudgetPickerViewModel(this._listBudgets, this._coin);

  static const _searchDebounce = Duration(milliseconds: 300);

  List<CustomerInfo> _budgets = const [];
  List<CustomerInfo> get budgets => _budgets;

  BudgetStatus? _status;
  BudgetStatus? get status => _status;

  String _query = '';
  bool _loading = true;
  bool get isLoading => _loading;

  Timer? _debounce;
  int _requestId = 0;
  bool _disposed = false;

  Future<void> init([String query = '']) {
    _query = query;
    return _load();
  }

  void selectStatus(BudgetStatus? status) {
    if (status == _status) return;
    _status = status;
    _load();
  }

  void search(String query) {
    _query = query;
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, _load);
  }

  String formatValue(CustomerInfo b) =>
      _coin.convertFromDouble(b.totalValue ?? 0);

  Future<void> _load() async {
    final request = ++_requestId;
    _loading = true;
    notifyListeners();
    final result = await _listBudgets(
      BudgetFilter(status: _status, clientName: _query),
    );
    // Ignora respostas de buscas antigas ou após o modal fechar.
    if (_disposed || request != _requestId) return;
    _budgets = switch (result) {
      Ok(:final value) => value,
      _ => const [],
    };
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
