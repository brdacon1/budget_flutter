import 'package:flutter/widgets.dart';

/// Textos da área de produto/serviço (lista de preço + cadastro de item)
/// internacionalizados.
///
/// Resolve o idioma a partir da **localidade do dispositivo**
/// ([WidgetsBinding.instance.platformDispatcher.locale]) e devolve a string
/// em `pt` (Português) ou `en` (Inglês, fallback para qualquer outra
/// localidade).
///
/// Uso: `ProductStrings.saveButton`, `ProductStrings.editTitle`, etc. Todos os
/// getters são `static`, então podem ser usados tanto na View quanto no
/// ViewModel (que só precisa de `package:flutter/widgets.dart`). Nenhum texto
/// visível ao usuário fica solto como literal nas telas de produto — todos
/// passam por aqui, centralizando a tradução num arquivo só.
class ProductStrings {
  const ProductStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  // --- Cabeçalho / títulos ---
  static String get editTitle => _isPt ? 'Editar item' : 'Edit item';
  static String get createTitle => _isPt ? 'Criar item' : 'Create item';
  static String get subtitle =>
      _isPt ? 'Cadastro de produto ou serviço' : 'Product or service registration';

  // --- Card de formulário ---
  static String get formCardTitle =>
      _isPt ? 'Dados do produto ou serviço' : 'Product or service data';
  static String get formCardSubtitleEdit =>
      _isPt ? 'Clique para editar' : 'Click to edit';
  static String get formCardSubtitleCreate =>
      _isPt ? 'Clique para criar' : 'Click to create';

  // --- Campos ---
  static String get selectCategoryTitle =>
      _isPt ? 'Selecione categoria' : 'Select category';
  static String get categoryHint =>
      _isPt ? 'Definir categoria' : 'Set category';
  static List<String> get categoryOptions =>
      _isPt ? <String>['Produtos', 'Serviços'] : <String>['Products', 'Services'];
  static String get unitHint =>
      _isPt ? 'Unidade de medida' : 'Unit of measure';
  static String get priceHint => _isPt ? 'Preço' : 'Price';
  static String get qtyHint => _isPt ? 'Quantidade' : 'Quantity';
  static String get descriptionHint => _isPt
      ? 'Escreva a descrição do produto ou serviço...'
      : 'Write the product or service description...';

  // --- Botões ---
  static String get saveButton => _isPt ? 'SALVAR' : 'SAVE';
  static String get updateButton => _isPt ? 'ATUALIZAR' : 'UPDATE';

  // --- Feedback (sucesso/erro) ---
  static String get doneTitle => _isPt ? 'Feito!' : 'Done!';
  static String get errorTitle => _isPt ? 'Erro!' : 'Error!';
  static String get addSuccess =>
      _isPt ? 'Item adicionado com sucesso!' : 'Item added successfully!';
  static String get updateSuccess =>
      _isPt ? 'Item atualizado com sucesso!' : 'Item updated successfully!';
  static String get addError => _isPt
      ? 'Não foi possível adicionar um novo item em sua lista de preço'
      : 'Could not add a new item to your price list';
  static String get updatePriceListError => _isPt
      ? 'Não foi possível atualizar o item em sua lista de preço'
      : 'Could not update the item in your price list';
  static String get updateOrcamentoError => _isPt
      ? 'Não foi possível atualizar o item na lista de orçamentos.'
      : 'Could not update the item in the budget list.';
  static String get defaultError =>
      _isPt ? 'Ocorreu um erro. Tente novamente.' : 'An error occurred. Try again.';

  // --- Lista de preço ---
  static String get listTitle => _isPt ? 'Lista de preço' : 'Price list';
  static String get searchHint => _isPt
      ? 'Digite a descrição do item...'
      : 'Type the item description...';

  // --- Carrinho (adicionar ao orçamento) ---
  static String get cartTitle =>
      _isPt ? 'Carrinho de produtos' : 'Product cart';
  static String get cartButton => _isPt ? 'ADICIONAR' : 'ADD';
  static String get cartAddSuccess => _isPt
      ? 'Itens adicionados na lista do orçamento com sucesso!'
      : 'Items added to the budget list successfully!';
  static String get cartAddError => _isPt
      ? 'Ocorreu um erro para adicionar os itens na lista do orçamento'
      : 'An error occurred while adding the items to the budget list';
  static String get cartWarningTitle => _isPt ? 'Ops!' : 'Oops!';
  static String get cartWarning => _isPt
      ? 'Você tem itens no carrinho. Por favor, escolha entre esvaziar o carrinho ou adicionar esses itens ao orçamento.'
      : 'You have items in the cart. Please choose between emptying the cart or adding these items to the budget.';

  // --- Remoção de itens ---
  static String get deleteListTitle =>
      _isPt ? 'Remover produtos' : 'Remove products';
  static String get deleteButton => _isPt ? 'EXCLUIR ITENS' : 'DELETE ITEMS';
  static String get deleteSuccess =>
      _isPt ? 'Itens removidos com sucesso!' : 'Items removed successfully!';
  static String get deleteError => _isPt
      ? 'Ocorreu um erro ao remover os itens.'
      : 'An error occurred while removing the items.';

  // --- Quantidade (modal de input) ---
  static String get qtyTitle =>
      _isPt ? 'Defina quantidade' : 'Set quantity';
  static String get qtyInputHint =>
      _isPt ? 'Digite a quantidade' : 'Type the quantity';

  // --- Plano premium ---
  static String get premiumError => _isPt
      ? 'Você não possuí o plano premium onde é possível cadastrar produtos ilimitados'
      : "You don't have the premium plan which allows registering unlimited products";
}
