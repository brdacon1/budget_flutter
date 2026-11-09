class ItemsListBudget {
  String? id;
  String? category;
  String? description;
  double? price;
  double? quantity;
  String? measure;
  double? total;
  String? idProduct;
  bool? checkBox;
  bool? selectProduct;
  int indice = 0;

  ItemsListBudget({
    this.id,
    this.category,
    this.description,
    this.price,
    this.quantity,
    this.measure,
    this.total,
    this.idProduct,
    this.checkBox,
    this.selectProduct,
  });

  ItemsListBudget.fromMap(dynamic json) {
    id = json['id'];
    category = json['CATEGORIA'];
    description = json['DESCRICAO'];
    price = _convertToDouble(json['PRECO']) ?? 0.toDouble();
    quantity = _convertToDouble(json['QTD']) ?? 0.toDouble();
    total = _convertToDouble(json['TOTAL']) ?? 0.toDouble();
    indice = json['indice'] ?? 0;
    measure = json['MEDIDA'];
    idProduct = json['IDPRODUCT'];
    checkBox = json['checkBox'];
    selectProduct = json['selectProduct'];
  }

  double? _convertToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null; // Unable to convert
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['CATEGORIA'] = category;
    data['DESCRICAO'] = description;
    data['PRECO'] = price;
    data['QTD'] = quantity;
    data['MEDIDA'] = measure;
    data['TOTAL'] = total;
    data['IDPRODUCT'] = idProduct;
    data['checkBox'] = checkBox;
    data['selectProduct'] = selectProduct;
    data['indice'] = indice;

    return data;
  }
}
