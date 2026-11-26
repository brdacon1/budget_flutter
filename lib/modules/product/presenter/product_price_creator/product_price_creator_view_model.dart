import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/enums/product_price_field_enum.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class ProductPriceCreatorViewModel extends ChangeNotifier {
  final ProductPriceRepository _productRepository =
      getIt<ProductPriceRepository>();
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
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

  /// Aplica a categoria escolhida pela View (o modal é aberto na View).
  void setCategory(String label) {
    _category = ItemCategory.values.firstWhere((c) => c.label == label);
    categoriaText.text = label;
    notifyListeners();
  }

  /// Salva/atualiza o item. A View escuta o comando (running/completed/error).
  late final Command0<void> saveCommand = Command0(_executeSave);

  /// Mensagem de falha da última tentativa (exibida pela View).
  String? errorMessage;

  /// Mensagem de sucesso conforme criação ou atualização.
  String get successMessage =>
      nameButton == ProductPtString.saveButton
          ? ProductPtString.addSuccess
          : ProductPtString.updateSuccess;

  Future<Result<void>> _executeSave() async {
    final cleanAmount = moneyConvert.convertFromString(priceController.text);
    final qtd = moneyConvert.convertQtdFromString(qtdText.text);
    final totalPrice = cleanAmount * qtd;
    errorMessage = null;
    final model = _buildModel(cleanAmount, qtd, totalPrice);

    String? error;
    if (nameButton == ProductPtString.saveButton) {
      error = await _create(model: model);
    } else if (nameButton == ProductPtString.updateButton && !fieldVisible) {
      error = await _updatePriceList(model: _buildModel(cleanAmount, 0, null));
    } else {
      error = await _updateOrcamento(model: model);
    }

    if (error != null) {
      errorMessage = error;
      return Result.error(Exception(error));
    }
    savedItem = model;
    return const Result.ok(null);
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
    saveCommand.dispose();
    categoriaText.dispose();
    unidadeText.dispose();
    qtdText.dispose();
    descricaoText.dispose();
    priceController.dispose();
    super.dispose();
  }
}
