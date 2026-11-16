import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/enums/product_price_field_enum.dart';
import 'package:oflite/shared/common/widgets/modals/option_bottom_modal_widget.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class ProductPriceCreatorViewModel extends ChangeNotifier {
  final ProductPriceRepository _productRepository =
      getIt<ProductPriceRepository>();
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final DisplayAlertRepository displayAlert = getIt<DisplayAlertRepository>();
  final LoadingEventRepository loadingEvent = getIt<LoadingEventRepository>();
  final ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();

  final ProductPriceModel item;

  final TextEditingController categoriaText = TextEditingController();

  /// Categoria escolhida. O texto do campo é só o label; o que é gravado é
  /// [ItemCategory.value] (ou o valor original, se desconhecido).
  ItemCategory? _category;
  final TextEditingController unidadeText = TextEditingController();
  final TextEditingController qtdText = TextEditingController();
  final TextEditingController descricaoText = TextEditingController();
  final MoneyMaskedTextController priceController = MoneyMaskedTextController(
    leftSymbol: 'R\$ ',
  );

  ProductPriceFieldType? selectedField;
  late bool isEditing;
  late bool fieldVisible;
  late String nameButton;
  late String titlePage;
  bool isSaving = false;

  /// Item salvo/atualizado após operação bem-sucedida (exposto para quem chamou o modal).
  ProductPriceModel? savedItem;

  final bool fromListItem;

  ProductPriceCreatorViewModel({
    required this.item,
    this.fromListItem = false,
  }) {
    _initFromItem();
  }

  void _initFromItem() {
    final hasDescricao =
        item.descricao != null &&
        item.descricao!.isNotEmpty &&
        item.descricao != 'null';

    isEditing = hasDescricao;
    if (isEditing) {
      nameButton = ProductPtString.updateButton;
      titlePage = ProductPtString.editTitle;
      _category = ItemCategory.fromValue(item.categoria);
      categoriaText.text = _category?.label ?? item.categoria ?? '';
      unidadeText.text = item.medida ?? '';
      qtdText.text = (item.qtd ?? 0).toString();
      priceController.text = moneyConvert.convertFromDouble(item.preco ?? 0);
      descricaoText.text = item.descricao ?? '';
      fieldVisible =
          item.idProduct != null &&
          item.idProduct != 'null' &&
          item.idProduct!.isNotEmpty;
    } else {
      fieldVisible = fromListItem;
      nameButton = ProductPtString.saveButton;
      titlePage = ProductPtString.createTitle;
      _category = ItemCategory.services;
      categoriaText.text = _category!.label;
      unidadeText.text = '';
      qtdText.text = '1';
      priceController.text = '';
      descricaoText.text = '';
    }
  }

  void selectField(ProductPriceFieldType field) {
    selectedField = field;
    notifyListeners();
  }

  Future<void> selectCategory(BuildContext context) async {
    final value = await showOptionBottomModal(
      context,
      title: ProductPtString.selectCategoryTitle,
      values: ItemCategory.values.map((c) => c.label).toList(),
    );
    if (value != null) {
      _category = ItemCategory.values.firstWhere((c) => c.label == value);
      categoriaText.text = value;
      notifyListeners();
    }
  }

  Future<void> save(BuildContext context) async {
    if (isSaving) return;
    isSaving = true;
    notifyListeners();

    final cleanAmount = moneyConvert.convertFromString(priceController.text);
    final qtd = moneyConvert.convertQtdFromString(qtdText.text);
    final totalPrice = cleanAmount * qtd;

    await loadingEvent.alertLoading(context);
    if (!context.mounted) return;
    String? error;

    if (nameButton == ProductPtString.saveButton) {
      error = await _create(model: _buildModel(cleanAmount, qtd, totalPrice));
    } else if (nameButton == ProductPtString.updateButton && !fieldVisible) {
      error = await _updatePriceList(model: _buildModel(cleanAmount, 0, null));
    } else {
      error = await _updateOrcamento(
        model: _buildModel(cleanAmount, qtd, totalPrice),
      );
    }

    if (!context.mounted) return;
    loadingEvent.closeLoading(context);

    isSaving = false;
    notifyListeners();

    if (error != null) {
      if (!context.mounted) return;
      await displayAlert.notificationError(
        context,
        ProductPtString.errorTitle,
        error,
      );
      return;
    }

    final successMessage =
        nameButton == ProductPtString.saveButton
            ? ProductPtString.addSuccess
            : ProductPtString.updateSuccess;
    if (!context.mounted) return;
    displayAlert.notification(
      context,
      ProductPtString.doneTitle,
      successMessage,
    );

    // Guarda o item salvo para quem chamou o modal
    savedItem = _buildModel(
      moneyConvert.convertFromString(priceController.text),
      moneyConvert.convertQtdFromString(qtdText.text),
      moneyConvert.convertFromString(priceController.text) *
          moneyConvert.convertQtdFromString(qtdText.text),
    );

    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }

  ProductPriceModel _buildModel(double preco, double qtd, double? total) {
    return ProductPriceModel(
      categoria: _category?.value ?? item.categoria,
      descricao: descricaoText.text,
      medida: unidadeText.text,
      preco: preco,
      qtd: qtd,
      total: total,
    );
  }

  Future<String?> _create({required ProductPriceModel model}) async {
    try {
      final result = await _productRepository.addProduct(model);
      if (result is Error<String?>) throw result.error;
      if (fromListItem) {
        final id = (result as Ok<String?>).value;
        final withId = model.copyWith(id: id);
        final budgetItem = ItemsBudget(
          id: id,
          category: withId.categoria,
          description: withId.descricao,
          price: withId.preco,
          quantity: withId.qtd,
          measure: withId.medida,
          total: withId.total,
          idProduct: id,
        );
        await _budgetRepository.saveBudgetItem(
          _budgetRepository.selectBudget.value?.id ?? '',
          budgetItem,
        );
      }
      return null;
    } catch (e) {
      return ProductPtString.addError;
    }
  }

  Future<String?> _updatePriceList({required ProductPriceModel model}) async {
    try {
      final result = await _productRepository.updateProduct(
        model.copyWith(id: item.id, idProduct: item.idProduct),
      );
      if (result is Error<void>) throw result.error;
      return null;
    } catch (e) {
      return ProductPtString.updatePriceListError;
    }
  }

  Future<String?> _updateOrcamento({required ProductPriceModel model}) async {
    try {
      final budgetItem = ItemsBudget(
        id: item.idProduct,
        category: model.categoria ?? ItemCategory.services.value,
        description: model.descricao,
        price: model.preco,
        quantity: model.qtd,
        measure: model.medida,
        total: model.total,
        idProduct: item.idProduct,
        checkBox: item.checkBox,
      );
      await _budgetRepository.saveBudgetItem(
        _budgetRepository.selectBudget.value?.id ?? '',
        budgetItem,
      );
      return null;
    } catch (e) {
      return ProductPtString.updateOrcamentoError;
    }
  }

  @override
  void dispose() {
    categoriaText.dispose();
    unidadeText.dispose();
    qtdText.dispose();
    descricaoText.dispose();
    priceController.dispose();
    super.dispose();
  }
}
