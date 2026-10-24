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

  CustomerInfo copyWith({
    String? id,
    String? data,
    String? street,
    String? generated,
    String? neighborhood,
    String? city,
    String? email,
    String? address,
    String? phone,
    String? customerName,
    String? companyName,
    String? status,
    String? zip,
    double? totalValue,
  }) {
    return CustomerInfo(
      id: id ?? this.id,
      data: data ?? this.data,
      street: street ?? this.street,
      generated: generated ?? this.generated,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      email: email ?? this.email,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      customerName: customerName ?? this.customerName,
      companyName: companyName ?? this.companyName,
      status: status ?? this.status,
      zip: zip ?? this.zip,
      totalValue: totalValue ?? this.totalValue,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ID'] = id;
    data['DATA'] = this.data;
    data['RUA'] = street;
    data['GERADO'] = generated;
    data['BAIRRO'] = neighborhood;
    data['CITY'] = city;
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
