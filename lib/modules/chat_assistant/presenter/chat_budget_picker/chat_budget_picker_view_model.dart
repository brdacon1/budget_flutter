import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_filter.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_page_usecase.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Modal de seleção de orçamento do chat: filtro por status + busca por
/// cliente. A leitura é paginada (por cursor) no
/// [ListBudgetsPageUsecase]; a próxima página vem ao rolar a lista.
class ChatBudgetPickerViewModel extends ChangeNotifier {
  final ListBudgetsPageUsecase _listBudgets;
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

  String? _cursor;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

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
    _loadingMore = false;
    notifyListeners();
    final filter = BudgetFilter(status: _status, clientName: _query);
    var items = <CustomerInfo>[];
    String? cursor;
    var hasMore = false;
    // Uma página pode vir vazia (status raro) mesmo havendo mais: continua
    // lendo até aparecer algo ou acabar.
    do {
      final result = await _listBudgets(filter, cursor: cursor);
      // Ignora respostas de buscas antigas ou após o modal fechar.
      if (_disposed || request != _requestId) return;
      if (result case Ok(:final value)) {
        items = [...items, ...value.items];
        cursor = value.cursor;
        hasMore = value.hasMore;
      } else {
        hasMore = false;
      }
    } while (items.isEmpty && hasMore);
    _budgets = items;
    _cursor = cursor;
    _hasMore = hasMore;
    _loading = false;
    notifyListeners();
  }

  /// Próxima página (chamada ao rolar perto do fim da lista).
  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final request = _requestId;
    _loadingMore = true;
    notifyListeners();
    final result = await _listBudgets(
      BudgetFilter(status: _status, clientName: _query),
      cursor: _cursor,
    );
    if (_disposed || request != _requestId) return;
    if (result case Ok(:final value)) {
      _budgets = [..._budgets, ...value.items];
      _cursor = value.cursor;
      _hasMore = value.hasMore;
    } else {
      _hasMore = false;
    }
    _loadingMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
