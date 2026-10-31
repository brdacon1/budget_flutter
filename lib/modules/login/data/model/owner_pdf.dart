class OwnerPdf {
  String? rua;
  String? empresa;
  String? email;
  String? cnpj;
  String? bairro;
  String? city;
  String? cep;
  String? fotoId;
  String? fone;
  String? logoName;

  OwnerPdf({
     this.rua,
     this.empresa,
     this.email,
     this.cnpj,
     this.bairro,
     this.city,
     this.cep,
     this.fotoId,
     this.fone,
     this.logoName,
  });

  factory OwnerPdf.fromJson(Map<String, dynamic>? json) {
    return OwnerPdf(
      rua: json?['RUA'] ?? '',
      empresa: json?['EMPRESA'] ?? '',
      email: json?['EMAIL'] ?? '',
      cnpj: json?['CNPJ'] ?? '',
      bairro: json?['BAIRRO'] ?? '',
      city: json?['CITY'] ?? '',
      cep: json?['CEP'] ?? '',
      fotoId: json?['FOTOID'] ?? '',
      fone: json?['FONE'] ?? '',
      logoName: json?['LOGONAME'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EMPRESA': empresa,
      'EMAIL': email,
      'CNPJ': cnpj,
      'BAIRRO': bairro,
      'CITY': city,
      'CEP': cep,
      'FOTOID': fotoId,
      'FONE': fone,
      'LOGONAME': logoName,
      'RUA': rua,
    };
  }
}
