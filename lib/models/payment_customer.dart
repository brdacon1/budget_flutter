
class PaymentCustomer {
  String? id;
  String? METODO;
  String? DESCRICAO;
  double? PRECO;

  PaymentCustomer({
    this.id,
    this.METODO,
    this.DESCRICAO,
    this.PRECO,
  });

  factory PaymentCustomer.fromMap(Map<String, dynamic> map) {
    return PaymentCustomer(
      id: map['id'],
      METODO: map['METODO'],
      DESCRICAO: map['DESCRICAO'],
      PRECO: map['PRECO'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'METODO': METODO,
      'DESCRICAO': DESCRICAO,
      'PRECO': PRECO,
    };
  }
}
