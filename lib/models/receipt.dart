library oflite.globals;

class Receipt {
  String? ID;
  String? DATA;
  String? DESCRICAO;
  double? VALORTOTAL;
  bool? checkBox;
  int indice = 0;

  Receipt({this.ID,
    this.DATA,
    this.DESCRICAO,
    this.VALORTOTAL});

  Receipt.fromMap(dynamic json) {
    ID = json['ID'];
    DATA = json['DATA'];
    DESCRICAO = json['DESCRICAO'];
    VALORTOTAL = json['VALORTOTAL'];
  }

  Map<String, dynamic> toMap() {
    return {
      'ID': ID,
      'DATA': DATA,
      'DESCRICAO': DESCRICAO,
      'VALORTOTAL': VALORTOTAL,
    };
  }
}