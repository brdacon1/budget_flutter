library oflite.globals;

class Recived {
  String? ID;
  String? DATA;
  String? DESCRICAO;
  double? VALORTOTAL;
  bool? checkBox;
  int indice = 0;

  Recived({this.ID,
    this.DATA,
    this.DESCRICAO,
    this.VALORTOTAL});

  Recived.fromMap(dynamic json) {
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