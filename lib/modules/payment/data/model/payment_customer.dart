class PaymentCustomer {
  String? id;
  String? METODO;
  String? description;
  double? PRECO;

  PaymentCustomer({this.id, this.METODO, this.description, this.PRECO});

  factory PaymentCustomer.fromMap(Map<String, dynamic> map) {
    return PaymentCustomer(
      id: map['id'],
      METODO: map['METODO'],
      description: map['DESCRICAO'],
      PRECO: map['PRECO'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'METODO': METODO,
      'DESCRICAO': description,
      'PRECO': PRECO,
    };
  }
}
