import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/product/presenter/product_price_creator/product_price_creator_view.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Gerenciamento de estado da tela de **lista de preço** (produtos/serviços).
class ProductPriceListViewModel extends ChangeNotifier {
  final ProductPriceRepository _productRepository =
      getIt<ProductPriceRepository>();
  final DisplayAlertRepository displayAlert = getIt<DisplayAlertRepository>();
  final LoadingEventRepository loadingEvent = getIt<LoadingEventRepository>();
  final ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();

  final TextEditingController searchController = TextEditingController();

  List<ProductPriceModel> _all = <ProductPriceModel>[];
  bool isLoading = false;

  /// Ids marcados pelo check circular para remoção.
  final Set<String> _selectedIds = <String>{};
  bool deleting = false;

  ProductPriceListViewModel();

  List<ProductPriceModel> get found {
    final query = searchController.text;
    if (query.isEmpty) return _all;
    final q = query.toLowerCase();
    return _all
        .where((x) => (x.descricao ?? '').toLowerCase().contains(q))
        .toList();
  }

  void onSearchChanged() => notifyListeners();

  Future<void> inicialData() async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _productRepository.fetchProducts();
      if (result is Ok<List<ProductPriceModel>>) {
        // Clona a lista para não contaminar o cache singleton do repositório
        final list = List<ProductPriceModel>.from(result.value);
        // Mantém só a seleção de itens que ainda existem.
        _selectedIds.retainWhere((id) => list.any((e) => e.id == id));
        _all = list;
      } else {
        _all = <ProductPriceModel>[];
      }
    } catch (_) {
      _all = <ProductPriceModel>[];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => inicialData();

  bool get selectionMode => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;
  bool isSelected(ProductPriceModel i) => _selectedIds.contains(i.id);

  bool get allFilteredSelected {
    final items = found;
    return items.isNotEmpty && items.every(isSelected);
  }

  void toggleSelect(ProductPriceModel i) {
    final id = i.id;
    if (id == null) return;
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    notifyListeners();
  }

  /// No modo remoção, o toque no card alterna a seleção (retorna `true`);
  /// fora dele não faz nada (retorna `false`) e a View abre a edição.
  bool toggleIfSelecting(ProductPriceModel i) {
    if (!selectionMode) return false;
    toggleSelect(i);
    return true;
  }

  void selectAllFiltered() {
    final ids = found.map((e) => e.id).whereType<String>();
    if (allFilteredSelected) {
      _selectedIds.removeAll(ids);
    } else {
      _selectedIds.addAll(ids);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// Remove os itens selecionados. Retorna `true` em caso de sucesso.
  Future<bool> deleteSelected() async {
    if (_selectedIds.isEmpty || deleting) return false;
    deleting = true;
    notifyListeners();
    final result = await _productRepository.deleteProducts(
      _selectedIds.toList(),
    );
    final ok = result is Ok<void>;
    if (ok) _selectedIds.clear();
    deleting = false;
    if (ok) {
      await inicialData();
    } else {
      notifyListeners();
    }
    return ok;
  }

  Future<void> openCreator(
    BuildContext context, {
    ProductPriceModel? item,
  }) async {
    await showProductPriceCreatorBottomModal(
      context,
      item: item ?? const ProductPriceModel(),
      fromListItem: false,
    );
    await inicialData();
  }

  Future<void> addNew(BuildContext context) async {
    final isPremium = getIt<GetAccessStatusUseCase>().hasFullAccess;
    if (!isPremium && found.length > 15) {
      await displayAlert.notificationError(
        context,
        ProductPtString.errorTitle,
        ProductPtString.premiumError,
      );
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionView()),
      );
      return;
    }
    if (!context.mounted) return;
    await openCreator(context);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
