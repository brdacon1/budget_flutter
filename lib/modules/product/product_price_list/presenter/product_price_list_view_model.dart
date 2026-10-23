import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/common/strings/product_strings.dart';
import 'package:oflite/shared/common/widgets/modals/items_list_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/text_input_bottom_modal_widget.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/global_uid_user.dart' as UID;
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:oflite/modules/product/product_price_creator/presenter/product_price_creator_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/http_request.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';

/// Gerenciamento de estado da tela de **lista de preço** (produtos/serviços).
///
/// `extends ChangeNotifier` → fornece `notifyListeners()` consumido pelo
/// `AnimatedBuilder` da View. Toda mutação de estado termina com
/// `notifyListeners()`. A View **nunca** chama `setState`.
///
/// Detém:
/// - a lista completa vinda do Firebase (`_all`) e a lista filtrada pela
///   busca (`found`);
/// - o carrinho de itens selecionados para adicionar ao orçamento
///   (`addItems`);
/// - a lista de itens marcados para exclusão (`deleteItems`);
/// - o estado visual de seleção (`checkBoxAppear`, `checkBoxProductVisible`,
///   `deleteVisible`);
/// - o `TextEditingController` da busca.
///
/// Toda a regra de persistência (Firebase `PRICELIST` e
/// `ORCAMENTOS/.../ITENS`) e os modais (carrinho/exclusão/quantidade) vivem
/// aqui — a View só delega as ações. Usa [ProductPriceModel] (padrão Flutter:
/// `fromJson`/`toJson`/`copyWith`) e converte para `ItemsBudget` só na
/// fronteira do modal `ItemsListBottomModalWidget` (via `toItemsBudget()`).
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Não guarda `BuildContext` como campo (chega por parâmetro nos métodos).
/// - Erros tratados via `DisplayAlert`; operação longa envolta em
///   `LoadingEvent` (abre/fecha loading).
/// - Após navegar/abrir modal que muta dados, chama `inicialData()` para
///   sincronizar.
class ProductPriceListViewModel extends ChangeNotifier {
  // --- Dependências / Services ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HttpRequest db = HttpRequest();
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  // --- Dados de entrada (imutáveis) ---
  final CustomerInfo? item;
  final bool fromMenu;

  // --- Estado da busca ---
  final TextEditingController searchController = TextEditingController();

  // --- Estado da lista ---
  List<ProductPriceModel> _all = <ProductPriceModel>[];
  bool isLoading = false;

  // --- Carrinho (adicionar ao orçamento) ---
  List<ProductPriceModel> addItems = <ProductPriceModel>[];

  // --- Seleção para exclusão ---
  List<ProductPriceModel> deleteItems = <ProductPriceModel>[];

  // --- Estado visual de seleção ---
  bool deleteVisible = false;
  bool checkBoxAppear = false; // exibe checkbox (leading) de exclusão
  bool checkBoxProductVisible = true; // exibe checkbox (trailing) de carrinho

  ProductPriceListViewModel({this.item, this.fromMenu = false});

  /// Lista filtrada pela busca. Recalculada a partir de [_all] a cada leitura,
  /// garantindo consistência imediata com o texto digitado.
  List<ProductPriceModel> get found {
    final query = searchController.text;
    if (query.isEmpty) return _all;
    final q = query.toLowerCase();
    return _all
        .where((x) => (x.descricao ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// Disparado ao digitar na busca — apenas notifica para reconstruir a lista.
  void onSearchChanged() => notifyListeners();

  /// Carrega os itens da `PRICELIST` e reaplica as seleções de carrinho e
  /// exclusão que ainda estejam pendentes, mantendo o estado visual estável
  /// após um recarregamento.
  Future<void> inicialData() async {
    isLoading = true;
    notifyListeners();
    try {
      final querySnapshot = await _firestore
          .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/PRICELIST')
          .get();

      var list = querySnapshot.docs.map<ProductPriceModel>((doc) {
        return ProductPriceModel.fromJson(doc.data())
            .copyWith(id: doc.id, checkBox: false, selectProduct: false);
      }).toList();

      // Reaplica seleção de carrinho mantida em memória.
      for (final cart in addItems) {
        final i = list.indexWhere((e) => e.id == cart.id);
        if (i != -1) {
          list[i] =
              list[i].copyWith(checkBox: false, indice: i, selectProduct: true);
        }
      }

      // Reaplica seleção de exclusão mantida em memória.
      for (final del in deleteItems) {
        final i = list.indexWhere((e) => e.id == del.id);
        if (i != -1) {
          list[i] =
              list[i].copyWith(checkBox: true, indice: i, selectProduct: false);
        }
      }

      _all = list;
    } catch (_) {
      _all = <ProductPriceModel>[];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => inicialData();

  /// Voltar: bloqueia se há itens no carrinho, avisando o usuário.
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

  /// Long-press no card: alterna o modo de seleção (exclusão x carrinho).
  /// Ao entrar no modo de exclusão limpa o carrinho; ao sair, limpa tudo.
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

  /// Checkbox de carrinho (trailing): pede a quantidade e adiciona ao
/// carrinho. Só age quando o item ainda não está selecionado (paridade com o
/// comportamento original).
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

  /// Checkbox de exclusão (leading): marca o item para remoção.
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

  /// Remove um item do carrinho e desmarca a seleção na lista.
  void removeFromCart(int index) {
    if (index < 0 || index >= addItems.length) return;
    final removed = addItems.removeAt(index);
    final i = _all.indexWhere((e) => e.id == removed.id);
    if (i != -1) {
      _all[i] = _all[i].copyWith(selectProduct: false);
    }
    notifyListeners();
  }

  /// Edita a quantidade de um item do carrinho via modal de input.
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

  /// Remove um item da lista de exclusão e desmarca o checkbox na lista.
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

  /// Abre o modal do carrinho para revisar/adicionar os itens ao orçamento.
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

  /// Persiste os itens do carrinho em `ORCAMENTOS/{IDORCAMENTO}/ITENS`,
  /// fecha o modal e recarrega a lista.
  Future<void> saveCart(BuildContext context) async {
    await loadingEvent.alertLoading(context);
    try {
      for (final cart in addItems) {
        await _firestore
            .collection(
                'EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${budget.IDORCAMENTO}/ITENS')
            .doc(cart.id)
            .set(<String, dynamic>{
          'CATEGORIA': cart.categoria,
          'DESCRICAO': cart.descricao,
          'PRECO': cart.preco,
          'QTD': cart.qtd,
          'MEDIDA': cart.medida,
          'TOTAL': cart.total,
          'IDPRODUCT': cart.id,
        });
      }
      addItems = <ProductPriceModel>[];
      deleteItems = <ProductPriceModel>[];
      deleteVisible = false;
      checkBoxProductVisible = true;
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      if (!context.mounted) return;
      Navigator.pop(context, true); // fecha o modal do carrinho
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

  /// Abre o modal de exclusão para revisar/remover os itens marcados.
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

  /// Exclui os itens marcados da `PRICELIST`, fecha o modal e recarrega a
  /// lista.
  Future<void> deleteSelected(BuildContext context) async {
    await loadingEvent.alertLoading(context);
    try {
      for (final del in deleteItems) {
        await _firestore
            .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/PRICELIST')
            .doc(del.id)
            .delete();
      }
      deleteItems = <ProductPriceModel>[];
      deleteVisible = false;
      checkBoxAppear = false;
      checkBoxProductVisible = true;
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      if (!context.mounted) return;
      Navigator.pop(context, true); // fecha o modal de exclusão
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

  /// Abre o criador/editor de item. Ao voltar, recarrega a lista.
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

  /// Botão de adicionar: bloqueia produtos ilimitados no plano grátis
  /// (limite de 15 itens) e direciona para a assinatura; caso contrário,
  /// abre o criador.
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
