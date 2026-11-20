import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/product/presenter/product_price_creator/product_price_creator_view.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/modules/product/presenter/product_price_list/components/modals/product_price_list_delete_bottom_modal_widget.dart';
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

  List<ProductPriceModel> deleteItems = <ProductPriceModel>[];

  bool deleteVisible = false;
  bool checkBoxAppear = false;

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
        var list = List<ProductPriceModel>.from(result.value);

        for (final del in deleteItems) {
          final i = list.indexWhere((e) => e.id == del.id);
          if (i != -1) {
            list[i] = list[i].copyWith(
              checkBox: true,
              indice: i,
              selectProduct: false,
            );
          }
        }
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

  void onLongPress() {
    checkBoxAppear = !checkBoxAppear;
    if (!checkBoxAppear) {
      _all = _all.map((e) => e.copyWith(checkBox: false)).toList();
      deleteItems = <ProductPriceModel>[];
      deleteVisible = false;
    }
    notifyListeners();
  }

  void toggleDeleteCheckbox(int index) {
    final list = found;
    if (index < 0 || index >= list.length) return;
    final current = list[index];
    if (current.checkBox == true) return;

    final updated = current.copyWith(
      checkBox: true,
      selectProduct: false,
      indice: index,
    );
    _replaceInAllById(updated);
    deleteItems.add(updated);
    if (deleteItems.length == 1) deleteVisible = true;
    notifyListeners();
  }

  void removeFromDeleteList(int index) {
    if (index < 0 || index >= deleteItems.length) return;
    final removed = deleteItems.removeAt(index);
    removeFromDeleteListByItem(removed);
  }

  void removeFromDeleteListByItem(ProductPriceModel removed) {
    deleteItems.remove(removed);
    final i = _all.indexWhere((e) => e.id == removed.id);
    if (i != -1) {
      _all[i] = _all[i].copyWith(checkBox: false);
    }
    if (deleteItems.isEmpty) {
      deleteVisible = false;
      checkBoxAppear = false;
    }
    notifyListeners();
  }

  void clearDeleteState() {
    deleteItems = <ProductPriceModel>[];
    deleteVisible = false;
    checkBoxAppear = false;
    _all = _all.map((e) => e.copyWith(checkBox: false)).toList();
    notifyListeners();
  }

  Future<void> openDeleteModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ProductPriceListDeleteBottomModalWidget(
            deleteItems: deleteItems,
            moneyConvert: moneyConvert,
            onRemove: removeFromDeleteListByItem,
            onConfirm: () => deleteSelected(context),
          ),
    );
    notifyListeners();
  }

  Future<void> deleteSelected(BuildContext context) async {
    await loadingEvent.alertLoading(context);
    try {
      for (final del in deleteItems) {
        if (del.id != null) {
          await _productRepository.deleteProduct(del.id!);
        }
      }
      deleteItems = <ProductPriceModel>[];
      deleteVisible = false;
      checkBoxAppear = false;
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      if (!context.mounted) return;
      Navigator.pop(context, true);
      if (!context.mounted) return;
      await displayAlert.notification(
        context,
        ProductPtString.doneTitle,
        ProductPtString.deleteSuccess,
      );
      await inicialData();
    } catch (_) {
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      if (!context.mounted) return;
      await displayAlert.notificationError(
        context,
        ProductPtString.errorTitle,
        ProductPtString.deleteError,
      );
    }
  }

  Future<void> openCreator(
    BuildContext context, {
    ProductPriceModel? item,
  }) async {
    await showProductPriceCreatorBottomModal(
      context,
      item: item ?? ProductPriceModel(),
      fromListItem: false,
    );
    await inicialData();
  }

  Future<void> addNew(BuildContext context) async {
    final isPremium =
        getIt<UserRepository>().selectUser.value?.autoRenewing ?? false;
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

  void _replaceInAllById(ProductPriceModel updated) {
    final i = _all.indexWhere((e) => e.id == updated.id);
    if (i != -1) _all[i] = updated;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
