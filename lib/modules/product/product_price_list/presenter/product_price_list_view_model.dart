import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:oflite/modules/product/product_price_creator/presenter/product_price_creator_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/strings/product_strings.dart';
import 'package:oflite/shared/common/widgets/modals/items_list_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/text_input_bottom_modal_widget.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/global_uid_user.dart' as UID;
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Gerenciamento de estado da tela de **lista de preço** (produtos/serviços).
class ProductPriceListViewModel extends ChangeNotifier {
  final ProductPriceRepository _productRepository = getIt<ProductPriceRepository>();
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  final CustomerInfo? item;
  final bool fromMenu;

  final TextEditingController searchController = TextEditingController();

  List<ProductPriceModel> _all = <ProductPriceModel>[];
  bool isLoading = false;

  List<ProductPriceModel> addItems = <ProductPriceModel>[];
  List<ProductPriceModel> deleteItems = <ProductPriceModel>[];

  bool deleteVisible = false;
  bool checkBoxAppear = false;
  bool checkBoxProductVisible = true;

  ProductPriceListViewModel({this.item, this.fromMenu = false});

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
        var list = result.value;
        for (final cart in addItems) {
          final i = list.indexWhere((e) => e.id == cart.id);
          if (i != -1) {
            list[i] = list[i]
                .copyWith(checkBox: false, indice: i, selectProduct: true);
          }
        }
        for (final del in deleteItems) {
          final i = list.indexWhere((e) => e.id == del.id);
          if (i != -1) {
            list[i] = list[i]
                .copyWith(checkBox: true, indice: i, selectProduct: false);
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

  Future<void> onBack(BuildContext context) async {
    if (addItems.isEmpty) {
      Navigator.pop(context, true);
      return;
    }
    await displayAlert.notificationWarning(
      context,
      ProductStrings.cartWarningTitle,
      ProductStrings.cartWarning,
    );
  }

  void onLongPress() {
    checkBoxAppear = !checkBoxAppear;
    checkBoxProductVisible = !checkBoxAppear;
    addItems = <ProductPriceModel>[];
    if (!checkBoxAppear) {
      _all = _all
          .map((e) => e.copyWith(checkBox: false, selectProduct: false))
          .toList();
      deleteItems = <ProductPriceModel>[];
      deleteVisible = false;
    }
    notifyListeners();
  }

  Future<void> toggleSelectProduct(BuildContext context, int index) async {
    final list = found;
    if (index < 0 || index >= list.length) return;
    final current = list[index];
    if (current.selectProduct == true) return;

    final value = await showTextInputBottomModal(
      context,
      title: ProductStrings.qtyTitle,
      hintText: ProductStrings.qtyInputHint,
    );
    if (value == null || value.isEmpty) return;

    final qtd = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    final total = qtd * (current.preco ?? 0);
    final updated = current.copyWith(
      selectProduct: true,
      indice: index,
      qtd: qtd,
      idProduct: current.id,
      total: total,
    );
    _replaceInAllById(updated);
    addItems.add(updated);
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
    checkBoxProductVisible = false;
    if (deleteItems.length == 1) deleteVisible = true;
    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= addItems.length) return;
    final removed = addItems.removeAt(index);
    final i = _all.indexWhere((e) => e.id == removed.id);
    if (i != -1) {
      _all[i] = _all[i].copyWith(selectProduct: false);
    }
    notifyListeners();
  }

  Future<void> editCartQty(BuildContext context, int index) async {
    if (index < 0 || index >= addItems.length) return;
    final value = await showTextInputBottomModal(
      context,
      title: ProductStrings.qtyTitle,
      hintText: ProductStrings.qtyInputHint,
    );
    if (value == null || value.isEmpty) return;
    final qtd = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    final cart = addItems[index];
    final total = qtd * (cart.preco ?? 0);
    addItems[index] = cart.copyWith(qtd: qtd, total: total);
    notifyListeners();
  }

  void removeFromDeleteList(int index) {
    if (index < 0 || index >= deleteItems.length) return;
    final removed = deleteItems.removeAt(index);
    final i = _all.indexWhere((e) => e.id == removed.id);
    if (i != -1) {
      _all[i] = _all[i].copyWith(checkBox: false);
    }
    if (deleteItems.isEmpty) {
      deleteVisible = false;
      checkBoxAppear = false;
      checkBoxProductVisible = true;
    }
    notifyListeners();
  }

  Future<void> openCartModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemsListBottomModalWidget(
        title: ProductStrings.cartTitle,
        items: addItems.map((e) => e.toItemsBudget()).toList(),
        moneyConvert: moneyConvert,
        buttonLabel: ProductStrings.cartButton,
        onRemove: (item, index) => removeFromCart(index),
        onItemTap: (item, index) async => await editCartQty(context, index),
        onButtonPressed: () => saveCart(context),
      ),
    );
    notifyListeners();
  }

  Future<void> saveCart(BuildContext context) async {
    await loadingEvent.alertLoading(context);
    try {
      final budgetRepo = getIt<BudgetRepository>();
      for (final cart in addItems) {
        final item = ItemsBudget(
          id: cart.id,
          CATEGORIA: cart.categoria,
          DESCRICAO: cart.descricao,
          PRECO: cart.preco,
          QTD: cart.qtd,
          MEDIDA: cart.medida,
          TOTAL: cart.total,
          IDPRODUCT: cart.id,
        );
        await budgetRepo.saveBudgetItem(budget.IDORCAMENTO ?? '', item);
      }
      addItems = <ProductPriceModel>[];
      deleteItems = <ProductPriceModel>[];
      deleteVisible = false;
      checkBoxProductVisible = true;
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      if (!context.mounted) return;
      Navigator.pop(context, true);
      if (!context.mounted) return;
      await displayAlert.notification(
        context,
        ProductStrings.doneTitle,
        ProductStrings.cartAddSuccess,
      );
      await inicialData();
    } catch (_) {
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      if (!context.mounted) return;
      await displayAlert.notificationError(
        context,
        ProductStrings.errorTitle,
        ProductStrings.cartAddError,
      );
    }
  }

  Future<void> openDeleteModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemsListBottomModalWidget(
        title: ProductStrings.deleteListTitle,
        items: deleteItems.map((e) => e.toItemsBudget()).toList(),
        moneyConvert: moneyConvert,
        buttonLabel: ProductStrings.deleteButton,
        onRemove: (item, index) => removeFromDeleteList(index),
        onButtonPressed: () => deleteSelected(context),
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
      checkBoxProductVisible = true;
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      if (!context.mounted) return;
      Navigator.pop(context, true);
      if (!context.mounted) return;
      await displayAlert.notification(
        context,
        ProductStrings.doneTitle,
        ProductStrings.deleteSuccess,
      );
      await inicialData();
    } catch (_) {
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      if (!context.mounted) return;
      await displayAlert.notificationError(
        context,
        ProductStrings.errorTitle,
        ProductStrings.deleteError,
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
    );
    await inicialData();
  }

  Future<void> addNew(BuildContext context) async {
    final isPremium = UID.autoRenewing ?? false;
    if (!isPremium && found.length > 15) {
      await displayAlert.notificationError(
        context,
        ProductStrings.errorTitle,
        ProductStrings.premiumError,
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
