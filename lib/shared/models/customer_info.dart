library oflite.globals;

class CustomerInfo {
  String? id;
  String? data;
  String? street;
  String? generated;
  String? neighborhood;
  String? city;
  String? zip;
  String? email;
  String? address;
  String? phone;
  String? customerName;
  String? companyName;
  String? status;
  double? totalValue;
  bool? checkBox;
  int index = 0;

  CustomerInfo({this.id,
    this.data,
    this.street,
    this.generated,
    this.neighborhood,
    this.city,
    this.email,
    this.address,
    this.phone,
    this.customerName,
    this.companyName,
    this.status,
    this.zip,
    this.totalValue});

  CustomerInfo.fromMap(dynamic json) {
    id = json['ID'];
    data = json['DATA'];
    street = json['RUA'];
    generated = json['GERADO'];
    neighborhood = json['BAIRRO'];
    city = json['CITY'];
    email = json['EMAIL'];
    address = json['ENDERECO'];
    phone = json['FONE'];
    customerName = json['NOMECLIENTE'];
    companyName = json['NOMEEMPRESA'];
    status = json['STATUS'];
    zip = json['CEP'];
    totalValue = json['VALORTOTAL'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ID'] = id;
    data['DATA'] = this.data;
    data['odata.etag'] = street;
    data['RUA'] = generated;
    data['BAIRRO'] = neighborhood;
    data['Id'] = city;
    data['EMAIL'] = email;
    data['ENDERECO'] = address;
    data['FONE'] = phone;
    data['NOMECLIENTE'] = customerName;
    data['NOMEEMPRESA'] = companyName;
    data['STATUS'] = status;
    data['CEP'] = zip;
    data['VALORTOTAL'] = totalValue;
    return data;
  }
}
