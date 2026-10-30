import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/items_list_budget_model.dart';

/// Model de item de produto/serviço da feature de **lista de preço**.
///
/// Diferente dos models antigos (`ItemsBudget`/`ItemsListBudget`) — que usam
/// `fromMap`/`toJson` sem `copyWith` e com campos públicos mutáveis — este
/// segue o **padrão de model do Flutter**:
///
/// - construtor `const` com campos `final` (imutável);
/// - `factory fromJson(Map<String, dynamic>)`;
/// - `Map<String, dynamic> toJson()`;
/// - `copyWith({...})`.
///
/// As chaves do `toJson`/`fromJson` mantêm o formato **maiúsculo** já gravado
/// no Firebase (`CATEGORIA`, `DESCRICAO`, `PRECO`, ...) para não quebrar os
/// documentos existentes — apenas a nomenclatura Dart muda para `camelCase`.
///
/// Como o `BudgetRemoteDataSource.saveBudgetItem` e outras
/// telas (`budget_list_items`, `product_price_list`, `ItemsListBottomModal`)
/// ainda usam os models legados, este model expõe **adapters de fronteira**
/// (`fromItemsBudget`/`toItemsListBudget`) para converter nas bordas sem
/// acoplar a feature inteira aos models antigos.
class ProductPriceModel {
  final String? id;
  final String? categoria;
  final String? descricao;
  final double? preco;
  final double? qtd;
  final String? medida;
  final double? total;
  final String? idProduct;
  final bool? checkBox;
  final bool? selectProduct;
  final int indice;

  const ProductPriceModel({
    this.id,
    this.categoria,
    this.descricao,
    this.preco,
    this.qtd,
    this.medida,
    this.total,
    this.idProduct,
    this.checkBox,
    this.selectProduct,
    this.indice = 0,
  });

  factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
    return ProductPriceModel(
      id: json['id'] as String?,
      categoria: json['CATEGORIA'] as String?,
      descricao: json['DESCRICAO'] as String?,
      preco: _toDouble(json['PRECO']),
      qtd: _toDouble(json['QTD']),
      medida: json['MEDIDA'] as String?,
      total: _toDouble(json['TOTAL']),
      idProduct: json['IDPRODUCT'] as String?,
      checkBox: json['checkBox'] as bool?,
      selectProduct: json['selectProduct'] as bool?,
      indice: (json['indice'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'CATEGORIA': categoria,
        'DESCRICAO': descricao,
        'PRECO': preco,
        'QTD': qtd,
        'MEDIDA': medida,
        'TOTAL': total,
        'IDPRODUCT': idProduct,
        'checkBox': checkBox,
        'selectProduct': selectProduct,
        'indice': indice,
      };

  ProductPriceModel copyWith({
    String? id,
    String? categoria,
    String? descricao,
    double? preco,
    double? qtd,
    String? medida,
    double? total,
    String? idProduct,
    bool? checkBox,
    bool? selectProduct,
    int? indice,
  }) {
    return ProductPriceModel(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      qtd: qtd ?? this.qtd,
      medida: medida ?? this.medida,
      total: total ?? this.total,
      idProduct: idProduct ?? this.idProduct,
      checkBox: checkBox ?? this.checkBox,
      selectProduct: selectProduct ?? this.selectProduct,
      indice: indice ?? this.indice,
    );
  }

  // -------------------------------------------------------------------------
  // Adapters de fronteira com os models legados compartilhados.
  //
  // `ItemsBudget`/`ItemsListBudget` ainda são usados por services e outras
  // telas. Em vez de espalhar conversões nas Views, a conversão fica aqui —
  // único ponto que conhece os dois formatos. Quando os models legados forem
  // migrados de fato, basta remover estes métodos.
  // -------------------------------------------------------------------------

  factory ProductPriceModel.fromItemsBudget(ItemsBudget item) {
    return ProductPriceModel(
      id: item.id,
      categoria: item.CATEGORIA,
      descricao: item.DESCRICAO,
      preco: item.PRECO,
      qtd: item.QTD,
      medida: item.MEDIDA,
      total: item.TOTAL,
      idProduct: item.IDPRODUCT,
      checkBox: item.checkBox,
      selectProduct: item.selectProduct,
      indice: item.indice,
    );
  }

  factory ProductPriceModel.fromItemsListBudget(ItemsListBudget item) {
    return ProductPriceModel(
      id: item.id,
      categoria: item.CATEGORIA,
      descricao: item.DESCRICAO,
      preco: item.PRECO,
      qtd: item.QTD,
      medida: item.MEDIDA,
      total: item.TOTAL,
      idProduct: item.IDPRODUCT,
      checkBox: item.checkBox,
      selectProduct: item.selectProduct,
      indice: item.indice,
    );
  }

  /// Converte para o model legado usado pelo service
  /// `BudgetRemoteDataSource.saveBudgetItem(ItemsListBudget)`.
  ItemsListBudget toItemsListBudget() {
    return ItemsListBudget(
      id: id,
      CATEGORIA: categoria,
      DESCRICAO: descricao,
      PRECO: preco,
      QTD: qtd,
      MEDIDA: medida,
      TOTAL: total,
      IDPRODUCT: idProduct,
      checkBox: checkBox,
      selectProduct: selectProduct,
    )..indice = indice;
  }

  /// Converte para o model legado compartilhado entre as telas de orçamento,
  /// lista de preço e o modal `ItemsListBottomModalWidget`.
  ItemsBudget toItemsBudget() {
    return ItemsBudget(
      id: id,
      CATEGORIA: categoria,
      DESCRICAO: descricao,
      PRECO: preco,
      QTD: qtd,
      MEDIDA: medida,
      TOTAL: total,
      IDPRODUCT: idProduct,
      checkBox: checkBox,
      selectProduct: selectProduct,
    )..indice = indice;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
