library oflite.globals;

class ObjectListItens {
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

  ObjectListItens({
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

  ObjectListItens.fromMap(dynamic json) {
    id = json['id'];
    CATEGORIA = json['CATEGORIA'];
    DESCRICAO = json['DESCRICAO'];
    PRECO = json['PRECO'];
    QTD = json['QTD'];
    MEDIDA = json['MEDIDA'];
    TOTAL = json['TOTAL'];
    IDPRODUCT = json['IDPRODUCT'];
    checkBox = json['checkBox'];
    selectProduct = json['selectProduct'];
    indice = json['indice'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
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
