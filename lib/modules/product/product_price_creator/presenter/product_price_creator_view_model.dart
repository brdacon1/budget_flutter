import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/common/enums/product_price_field_enum.dart';
import 'package:oflite/shared/common/strings/product_strings.dart';
import 'package:oflite/shared/common/widgets/modals/option_bottom_modal_widget.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/global_uid_user.dart' as UID;
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/http_request.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';

/// Gerenciamento de estado da tela de criação/edição de produto ou serviço.
///
/// `extends ChangeNotifier` → fornece `notifyListeners()` consumido pelo
/// `AnimatedBuilder` da View. Toda mutação de estado termina com
/// `notifyListeners()`. A View **nunca** chama `setState`.
///
/// Detém os controllers dos campos, o estado de qual campo está focado, se é
/// edição ou criação, se o campo de quantidade é visível e o rótulo do
/// botão. Toda a regra de persistência (Firebase `PRICELIST` e
/// `ORCAMENTOS/.../ITENS`) vive aqui — a View só delega `save(context)`.
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Não guarda `BuildContext` como campo (chega por parâmetro em `save`).
/// - Erros tratados via `DisplayAlert`; operação longa envolta em
///   `LoadingEvent` (abre/fecha loading).
/// - Usa [ProductPriceModel] (padrão Flutter: `fromJson`/`toJson`/`copyWith`)
///   e converte para os models legados só na fronteira dos services
///   compartilhados.
class ProductPriceCreatorViewModel extends ChangeNotifier {
  // --- Dependências / Services ---
  final HttpRequest db = HttpRequest();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  // --- Item recebido (edição) ---
  final ProductPriceModel item;

  // --- Controllers dos campos ---
  final TextEditingController categoriaText = TextEditingController();
  final TextEditingController unidadeText = TextEditingController();
  final TextEditingController qtdText = TextEditingController();
  final TextEditingController descricaoText = TextEditingController();
  final MoneyMaskedTextController priceController =
      MoneyMaskedTextController(leftSymbol: 'R\$ ');

  // --- Estado visual reativo ---
  ProductPriceFieldType? selectedField;
  late bool isEditing;
  late bool fieldVisible;
  late String nameButton;
  late String titlePage;
  bool isSaving = false;

  ProductPriceCreatorViewModel({required this.item}) {
    _initFromItem();
  }

  /// Popula os controllers e o estado a partir do [item] recebido, espelhando
  /// o antigo `initState` da View. `DESCRICAO` em branco/nula indica criação.
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

  /// Registra a interação com um campo (destaque do campo focado).
  void selectField(ProductPriceFieldType field) {
    selectedField = field;
    notifyListeners();
  }

  /// Abre o modal de seleção de categoria e aplica o valor escolhido.
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

  /// Persiste o item (criação ou atualização). Recebe `BuildContext` apenas
  /// para UI (loading/alertas/navegação) — não o guarda como campo.
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

  /// Monta o [ProductPriceModel] a partir dos controllers.
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

  /// Cria o item na `PRICELIST` e, quando vindo de um orçamento
  /// (`budget.fromListItem`), também o replica em `ORCAMENTOS/.../ITENS`
  /// via o service compartilhado. Retorna `null` em sucesso ou a mensagem
  /// de erro.
  Future<String?> _create({required ProductPriceModel model}) async {
    try {
      final doc = await _firestore
          .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/PRICELIST')
          .add(model.toJson()..['COLOR'] = 'false');

      if (budget.fromListItem == true) {
        final withId = model.copyWith(id: doc.id);
        await db.salvaItensList(withId.toItemsListBudget());
      }
      return null;
    } catch (e) {
      return ProductStrings.addError;
    }
  }

  /// Atualiza o item na `PRICELIST` (item sem vínculo com orçamento).
  Future<String?> _updatePriceList({required ProductPriceModel model}) async {
    try {
      await _firestore
          .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/PRICELIST')
          .doc(item.id)
          .update(<String, dynamic>{
        'CATEGORIA': model.categoria,
        'DESCRICAO': model.descricao,
        'PRECO': model.preco,
        'QTD': model.qtd,
        'MEDIDA': model.medida,
        'TOTAL': model.total,
        'COLOR': 'false',
        'IDPRODUCT': model.idProduct,
      });
      return null;
    } catch (e) {
      return ProductStrings.updatePriceListError;
    }
  }

  /// Atualiza o item em `ORCAMENTOS/{IDORCAMENTO}/ITENS` (item vinculado a um
  /// orçamento). O doc id é o `IDPRODUCT` do item recebido e o `COLOR` é o
  /// `checkBox` original — preservando o comportamento anterior.
  Future<String?> _updateOrcamento({required ProductPriceModel model}) async {
    try {
      await _firestore
          .collection(
              'EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${budget.IDORCAMENTO}/ITENS')
          .doc(item.idProduct)
          .update(<String, dynamic>{
        'CATEGORIA': model.categoria ?? 'Serviços',
        'DESCRICAO': model.descricao,
        'PRECO': model.preco,
        'QTD': model.qtd,
        'MEDIDA': model.medida,
        'TOTAL': model.total,
        'COLOR': item.checkBox,
        'IDPRODUCT': item.idProduct,
      });
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
