class OwnerInfo {
  String cnpj;
  String empresa;
  String adm;
  String segmento;
  String rua;
  String bairro;
  String city;
  String cep;
  String uid;

  OwnerInfo({
    required this.cnpj,
    required this.empresa,
    required this.adm,
    required this.segmento,
    required this.rua,
    required this.bairro,
    required this.city,
    required this.cep,
    required this.uid,
  });

  factory OwnerInfo.fromMap(Map<String, dynamic> map) {
    return OwnerInfo(
      cnpj: map['CNPJ'] as String,
      empresa: map['EMPRESA'] as String,
      adm: map['ADM'] as String,
      segmento: map['SEGMENTO'] as String,
      rua: map['RUA'] as String,
      bairro: map['BAIRRO'] as String,
      city: map['CITY'] as String,
      cep: map['CEP'] as String,
      uid: map['UID'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'CNPJ': cnpj,
      'EMPRESA': empresa,
      'ADM': adm,
      'SEGMENTO': segmento,
      'RUA': rua,
      'BAIRRO': bairro,
      'CITY': city,
      'CEP': cep,
      'UID': uid,
    };
  }
}
