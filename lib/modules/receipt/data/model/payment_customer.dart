class PaymentCustomer {
  String? id;
  String? method;
  String? description;
  double? price;

  PaymentCustomer({this.id, this.method, this.description, this.price});

  factory PaymentCustomer.fromMap(Map<String, dynamic> map) {
    return PaymentCustomer(
      id: map['id'],
      method: map['METODO'],
      description: map['DESCRICAO'],
      price: map['PRECO'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'METODO': method,
      'DESCRICAO': description,
      'PRECO': price,
    };
  }
}
