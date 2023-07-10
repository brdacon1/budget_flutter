class Owner {
  String? rua;
  String? empresa;
  String? email;
  String? cnpj;
  String? nomeOwner;
  String? bairro;
  String? city;
  String? cep;
  String? fotoId;
  String? fone;
  String? logoName;

  Owner({
     this.rua,
     this.empresa,
     this.email,
     this.cnpj,
     this.nomeOwner,
     this.bairro,
     this.city,
     this.cep,
     this.fotoId,
     this.fone,
     this.logoName,
  });

  factory Owner.fromJson(Map<String, dynamic>? json) { // Adicione '?' após 'dynamic'
    return Owner(
      rua: json?['DATA'] ?? '',
      empresa: json?['EMPRESA'] ?? '',
      email: json?['EMAIL'] ?? '',
      cnpj: json?['CNPJ'] ?? '',
      nomeOwner: json?['NOMEOWNER'] ?? '',
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
      'DATA': rua,
      'EMPRESA': empresa,
      'EMAIL': email,
      'CNPJ': cnpj,
      'NOMEOWNER': nomeOwner,
      'BAIRRO': bairro,
      'CITY': city,
      'CEP': cep,
      'FOTOID': fotoId,
      'FONE': fone,
      'LOGONAME': logoName,
    };
  }
}
