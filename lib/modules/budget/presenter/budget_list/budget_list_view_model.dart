import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/budget/domain/entity/budget_filter.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/duplicate_budget_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/create_budget_for_customer_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/watch_customer_budgets_usecase.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/map_launcher/domain/usecase/resolve_address_maps_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

TextEditingController searchController = TextEditingController();

class BudgetListViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final DuplicateBudgetUsecase _duplicateBudget =
      getIt<DuplicateBudgetUsecase>();
  final DisplayAlertRepository displayAlert = getIt<DisplayAlertRepository>();
  final ListBudgetsUsecase _listBudgets = getIt<ListBudgetsUsecase>();
  final ResolveAddressMapsUsecase _resolveMaps =
      getIt<ResolveAddressMapsUsecase>();
  final WatchCustomerBudgetsUsecase _watchCustomerBudgets =
      getIt<WatchCustomerBudgetsUsecase>();
  final CreateBudgetForCustomerUsecase _createForCustomer =
      getIt<CreateBudgetForCustomerUsecase>();

  /// Modo "Orçamentos do cliente": a lista são os orçamentos com o mesmo
  /// telefone de [customer], em tempo real. `null` = lista principal.
  CustomerInfo? customer;
  bool get isCustomerMode => customer != null;
  bool get customerHasPhone => (customer?.phone ?? '').trim().isNotEmpty;
  StreamSubscription<Result<List<CustomerInfo>>>? _customerSubscription;
  List<CustomerInfo> _customerBudgets = const [];

  /// Como abrir o endereço do cliente no mapa (Android: seletor nativo já
  /// aberto; iOS: apps para a action sheet).
  Future<AddressMapsResult> resolveMaps(CustomerInfo item) =>
      _resolveMaps(item.fullAddress);

  /// Filtro por status: recurso só de assinantes.
  bool get canFilterStatus =>
      (isCustomerMode && customerHasPhone) ||
      (getIt<UserRepository>().selectUser.value?.autoRenewing ?? false);

  BudgetStatus? _status;
  BudgetStatus? get status => _status;

  /// Resultado da busca no banco (nome e/ou status). `null` = sem filtro,
  /// a tela mostra a lista paginada.
  List<CustomerInfo>? _searchResults;
  bool _searching = false;
  bool get isSearching => _searching;
  Timer? _debounce;
  int _searchRequest = 0;

  bool _disposed = false;

  BudgetListViewModel() {
    _budgetRepository.addListener(_onBudgetRepoChanged);
  }

  CustomerInfo customerBudget = CustomerInfo();
  final _foundUsers = <CustomerInfo>[];
  CustomerInfo _customerInfoNew = CustomerInfo();

  /// Ids dos orçamentos selecionados para exclusão. Guardar o id (e não o
  /// objeto) mantém a seleção correta mesmo quando a lista é recarregada.
  final Set<String> selectedIds = <String>{};
  bool deleting = false;
  bool _isRefreshing = false;

  bool get selectionMode => selectedIds.isNotEmpty;

  bool isSelected(CustomerInfo b) => selectedIds.contains(b.id);

  int _totalBudgetCount = 0;
  int get totalBudgetCount => _totalBudgetCount;

  Future<void> loadCount() async {
    final result = await _budgetRepository.countBudgets();
    if (result is Ok<int>) {
      _totalBudgetCount = result.value;
      if (!_disposed) notifyListeners();
    }
  }

  bool get isRefreshing => _isRefreshing;

  bool get isLoadingMore => _budgetRepository.isLoadingMoreBudgets;
  bool get hasMoreBudgets => _budgetRepository.hasMoreBudgets;

  Future<void> loadMore() async {
    if (isCustomerMode ||
        _searchResults != null ||
        _isRefreshing ||
        !hasMoreBudgets) {
      return;
    }
    await getInformationOrcamento(refresh: false);
  }

  /// O repositório já mantém o cache paginado em sincronia (save/update/
  /// delete/duplicate), então só espelhamos — sem buscar a próxima página
  /// e sem resetar a paginação (preserva o scroll).
  void _onBudgetRepoChanged() {
    if (_disposed || _isRefreshing || isCustomerMode) return;
    _foundUsers
      ..clear()
      ..addAll(_budgetRepository.budgets);
    notifyListeners();
  }

  Future<void> initialScreen() async {
    await loadCount();
    if (isCustomerMode) return _watchCustomer();
    await getInformationOrcamento(refresh: true);
  }

  /// Escuta o Firestore: a lista do cliente atualiza sozinha.
  void _watchCustomer() {
    if (!customerHasPhone) return;
    _isRefreshing = true;
    _customerSubscription?.cancel();
    _customerSubscription = _watchCustomerBudgets(customer!.phone!).listen((
      result,
    ) {
      if (_disposed) return;
      _isRefreshing = false;
      if (result is Ok<List<CustomerInfo>>) {
        _customerBudgets = result.value;
      }
      notifyListeners();
    });
  }

  /// Cria orçamento com os dados do cliente (modo cliente).
  Future<CustomerInfo?> createForCustomer() async {
    final result = await _createForCustomer(customer!);
    if (result is Ok<CustomerInfo>) {
      _totalBudgetCount++;
      return result.value;
    }
    return null;
  }

  Future<void> duplicateEvent(
    bool clientData,
    bool quoteItems,
    bool comments,
    bool receipts,
  ) async {
    final String? originalId = _budgetRepository.selectBudget.value?.id;
    if (originalId == null || originalId.isEmpty) return;

    final result = await _duplicateBudget(
      sourceId: originalId,
      copyClientData: clientData,
      copyItems: quoteItems,
      copyComments: comments,
      copyReceipts: receipts,
    );

    if (result is Ok<CustomerInfo>) {
      customerBudget = result.value;
      _budgetRepository.clearSelectBudget();
      _totalBudgetCount++;
      if (!_disposed) notifyListeners();
      await getInformationOrcamento(refresh: true);
    }
  }

  /// Remove os orçamentos selecionados. Retorna `true` em caso de sucesso.
  Future<bool> deleteSelected() async {
    if (selectedIds.isEmpty || deleting) return false;
    deleting = true;
    if (!_disposed) notifyListeners();
    final items = getFilteredData().where(isSelected).toList();
    final result = await _budgetRepository.deleteBudgets(items);
    deleting = false;
    if (result is Ok<void>) {
      _totalBudgetCount -= items.length;
      selectedIds.clear();
      await getInformationOrcamento(refresh: true);
      return true;
    }
    if (!_disposed) notifyListeners();
    return false;
  }

  Future<List<CustomerInfo>> getInformationOrcamento({
    bool refresh = true,
  }) async {
    // Modo cliente: o stream já mantém a lista atualizada.
    if (isCustomerMode) return getFilteredData();
    _isRefreshing = true;
    final result = await _budgetRepository.fetchBudgetsPaginated(
      refresh: refresh,
    );
    _foundUsers.clear();
    if (result is Ok<List<CustomerInfo>>) {
      _foundUsers.addAll(result.value);
    }
    _isRefreshing = false;
    if (!_disposed) notifyListeners();
    if (searchController.text.trim().isNotEmpty || _status != null) {
      await _search();
    }
    return _foundUsers;
  }

  void onSearchTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  void selectStatus(BudgetStatus? status) {
    if (status == _status) return;
    _status = status;
    if (isCustomerMode) {
      notifyListeners();
      return;
    }
    _search();
  }

  /// Busca no banco por nome (prefixo) e/ou status. Sem filtro, volta para
  /// a lista paginada.
  Future<void> _search() async {
    final name = searchController.text.trim();
    final request = ++_searchRequest;
    if (name.isEmpty && _status == null) {
      _searchResults = null;
      _searching = false;
      if (!_disposed) notifyListeners();
      return;
    }
    _searching = true;
    if (!_disposed) notifyListeners();
    final result = await _listBudgets(
      BudgetFilter(status: _status, clientName: name),
    );
    // Ignora respostas de buscas antigas ou após sair da tela.
    if (_disposed || request != _searchRequest) return;
    _searchResults = switch (result) {
      Ok(:final value) => value,
      _ => const [],
    };
    _searching = false;
    notifyListeners();
  }

  /// Orçamento de onde o usuário veio (modo cliente).
  bool isOrigin(CustomerInfo b) => isCustomerMode && b.id == customer!.id;

  /// Modo cliente: o orçamento de origem sempre em primeiro.
  List<CustomerInfo> getFilteredData() {
    if (!isCustomerMode) return _searchResults ?? _foundUsers;
    return [
      ..._customerBudgets.where(isOrigin),
      ..._customerBudgets.where(
        (b) =>
            !isOrigin(b) &&
            (_status == null ||
                (b.status ?? '').toUpperCase() == _status!.value),
      ),
    ];
  }

  void toggleSelect(CustomerInfo b) {
    final id = b.id;
    if (id == null || isOrigin(b)) return;
    if (!selectedIds.remove(id)) selectedIds.add(id);
    if (!_disposed) notifyListeners();
  }

  void selectAllFiltered() {
    final ids =
        getFilteredData()
            .where((b) => !isOrigin(b))
            .map((b) => b.id)
            .whereType<String>();
    if (ids.every(selectedIds.contains)) {
      selectedIds.removeAll(ids);
    } else {
      selectedIds.addAll(ids);
    }
    if (!_disposed) notifyListeners();
  }

  void clearSelection() {
    selectedIds.clear();
    if (!_disposed) notifyListeners();
  }

  CustomerInfo customerInfoNew() {
    _customerInfoNew = CustomerInfo(
      phone: '',
      customerName: '',
      address: '',
      email: '',
      generated: '',
      data: '',
      status: 'PENDENTE',
      zip: '',
      city: '',
      neighborhood: '',
      id: '',
      street: '',
    );
    _budgetRepository.clearSelectBudget();
    return _customerInfoNew;
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _customerSubscription?.cancel();
    _budgetRepository.removeListener(_onBudgetRepoChanged);
    super.dispose();
  }
}
