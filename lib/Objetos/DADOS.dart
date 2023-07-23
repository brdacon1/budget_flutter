library oflite.globals;

class DADOS {
  String? ID;
  String? DATA;
  String? RUA;
  String? GERADO;
  String? BAIRRO;
  String? CITY;
  String? CEP;
  String? EMAIL;
  String? ENDERECO;
  String? FONE;
  String? NOMECLIENTE;
  String? NOMEEMPRESA;
  String? STATUS;
  double? VALORTOTAL;
  bool? checkBox;
  int indice = 0;

  DADOS({this.ID,
        this.DATA,
        this.RUA,
        this.GERADO,
        this.BAIRRO,
        this.CITY,
        this.EMAIL,
        this.ENDERECO,
        this.FONE,
        this.NOMECLIENTE,
        this.NOMEEMPRESA,
        this.STATUS,
        this.CEP,
        this.VALORTOTAL});

   DADOS.fromMap(dynamic json) {
    ID = json['ID'];
    DATA = json['DATA'];
    RUA = json['RUA'];
    GERADO = json['GERADO'];
    BAIRRO = json['BAIRRO'];
    CITY = json['CITY'];
    EMAIL = json['EMAIL'];
    ENDERECO = json['ENDERECO'];
    FONE = json['FONE'];
    NOMECLIENTE = json['NOMECLIENTE'];
    NOMEEMPRESA = json['NOMEEMPRESA'];
    STATUS = json['STATUS'];
    CEP = json['CEP'];
    VALORTOTAL = json['VALORTOTAL'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ID'] = this.ID;
    data['DATA'] = this.DATA;
    data['odata.etag'] = this.RUA;
    data['RUA'] = this.GERADO;
    data['BAIRRO'] = this.BAIRRO;
    data['Id'] = this.CITY;
    data['EMAIL'] = this.EMAIL;
    data['ENDERECO'] = this.ENDERECO;
    data['FONE'] = this.FONE;
    data['NOMECLIENTE'] = this.NOMECLIENTE;
    data['NOMEEMPRESA'] = this.NOMEEMPRESA;
    data['STATUS'] = this.STATUS;
    data['CEP'] = this.CEP;
    data['VALORTOTAL'] = this.VALORTOTAL;
    return data;
  }
}