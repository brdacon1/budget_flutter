import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/shared/common/enums/product_price_field_enum.dart';
import 'package:oflite/shared/common/strings/product_strings.dart';
import 'package:oflite/shared/common/widgets/modals/option_bottom_modal_widget.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class ProductPriceCreatorViewModel extends ChangeNotifier {
  final ProductPriceRepository _productRepository = getIt<ProductPriceRepository>();
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  final ProductPriceModel item;

  final TextEditingController categoriaText = TextEditingController();
  final TextEditingController unidadeText = TextEditingController();
  final TextEditingController qtdText = TextEditingController();
  final TextEditingController descricaoText = TextEditingController();
  final MoneyMaskedTextController priceController =
      MoneyMaskedTextController(leftSymbol: 'R\$ ');

  ProductPriceFieldType? selectedField;
  late bool isEditing;
  late bool fieldVisible;
  late String nameButton;
  late String titlePage;
  bool isSaving = false;

  ProductPriceCreatorViewModel({required this.item}) {
    _initFromItem();
  }

  void _initFromItem() {
    final hasDescricao = item.descricao != null &&
        item.descricao!.isNotEmpty &&
        item.descricao != 'null';

    isEditing = hasDescricao;
    if (isEditing) {
      nameButton = ProductStrings.updateButton;
      titlePage = ProductStrings.editTitle;
      categoriaText.text = item.categoria ?? '';
      unidadeText.text = item.medida ?? '';
      qtdText.text = (item.qtd ?? 0).toString();
      priceController.text = moneyConvert.convertFromDouble(item.preco ?? 0);
      descricaoText.text = item.descricao ?? '';
      fieldVisible = item.idProduct != null &&
          item.idProduct != 'null' &&
          item.idProduct!.isNotEmpty;
    } else {
      fieldVisible = budget.fromListItem == true;
      nameButton = ProductStrings.saveButton;
      titlePage = ProductStrings.createTitle;
      categoriaText.text = 'Serviços';
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
      title: ProductStrings.selectCategoryTitle,
      values: ProductStrings.categoryOptions,
    );
    if (value != null) {
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

    if (nameButton == ProductStrings.saveButton) {
      error = await _create(model: _buildModel(cleanAmount, qtd, totalPrice));
    } else if (nameButton == ProductStrings.updateButton && !fieldVisible) {
      error =
          await _updatePriceList(model: _buildModel(cleanAmount, 0, null));
    } else {
      error =
          await _updateOrcamento(model: _buildModel(cleanAmount, qtd, totalPrice));
    }

    if (!context.mounted) return;
    loadingEvent.closeLoading(context);

    isSaving = false;
    notifyListeners();

    if (error != null) {
      if (!context.mounted) return;
      await displayAlert.notificationError(
          context, ProductStrings.errorTitle, error);
      return;
    }

    final successMessage = nameButton == ProductStrings.saveButton
        ? ProductStrings.addSuccess
        : ProductStrings.updateSuccess;
    if (!context.mounted) return;
    displayAlert.notification(context, ProductStrings.doneTitle, successMessage);
    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }

  ProductPriceModel _buildModel(double preco, double qtd, double? total) {
    return ProductPriceModel(
      categoria: categoriaText.text,
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
      if (budget.fromListItem == true) {
        final id = (result as Ok<String?>).value;
        final withId = model.copyWith(id: id);
        final budgetItem = ItemsBudget(
          id: id,
          CATEGORIA: withId.categoria,
          DESCRICAO: withId.descricao,
          PRECO: withId.preco,
          QTD: withId.qtd,
          MEDIDA: withId.medida,
          TOTAL: withId.total,
          IDPRODUCT: id,
        );
        await _budgetRepository.saveBudgetItem(
            budget.IDORCAMENTO ?? '', budgetItem);
      }
      return null;
    } catch (e) {
      return ProductStrings.addError;
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
      return ProductStrings.updatePriceListError;
    }
  }

  Future<String?> _updateOrcamento({required ProductPriceModel model}) async {
    try {
      final budgetItem = ItemsBudget(
        id: item.idProduct,
        CATEGORIA: model.categoria ?? 'Serviços',
        DESCRICAO: model.descricao,
        PRECO: model.preco,
        QTD: model.qtd,
        MEDIDA: model.medida,
        TOTAL: model.total,
        IDPRODUCT: item.idProduct,
        checkBox: item.checkBox,
      );
      await _budgetRepository.saveBudgetItem(
          budget.IDORCAMENTO ?? '', budgetItem);
      return null;
    } catch (e) {
      return ProductStrings.updateOrcamentoError;
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
