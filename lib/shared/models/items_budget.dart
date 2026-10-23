library oflite.globals;

class ItemsBudget {
  String? id;
  String? CATEGORIA;
  String? DESCRICAO;
  double? PRECO;
  double? QTD;
  String? MEDIDA;
  double? TOTAL;
  String? IDPRODUCT;
  bool? checkBox;
  bool? selectProduct;
  int indice = 0;

  ItemsBudget({
    this.id,
    this.CATEGORIA,
    this.DESCRICAO,
    this.PRECO,
    this.QTD,
    this.MEDIDA,
    this.TOTAL,
    this.IDPRODUCT,
    this.checkBox,
    this.selectProduct,
  });

  ItemsBudget.fromMap(dynamic json) {
    id = json['id'];
    CATEGORIA = json['CATEGORIA'];
    DESCRICAO = json['DESCRICAO'];
    PRECO = _convertToDouble(json['PRECO']) ?? 0;
    QTD = _convertToDouble(json['QTD']) ?? 0;
    MEDIDA = json['MEDIDA'];
    TOTAL = _convertToDouble(json['TOTAL']) ?? 0;
    IDPRODUCT = json['IDPRODUCT'];
    checkBox = json['checkBox'];
    selectProduct = json['selectProduct'];
    indice = json['indice'] ?? 0;
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
    data['id'] = this.id;
    data['CATEGORIA'] = this.CATEGORIA;
    data['DESCRICAO'] = this.DESCRICAO;
    data['PRECO'] = this.PRECO;
    data['QTD'] = this.QTD;
    data['MEDIDA'] = this.MEDIDA;
    data['TOTAL'] = this.TOTAL;
    data['IDPRODUCT'] = this.IDPRODUCT;
    data['checkBox'] = this.checkBox;
    data['selectProduct'] = this.selectProduct;
    data['indice'] = this.indice;

    return data;
  }
}
