import 'package:cloud_firestore/cloud_firestore.dart';

class ObjectPagamentosCliente {
  String? id;
  String? METODO;
  String? DESCRICAO;
  String? PRECO;
  String? QTDDIV;
  bool? selectProduct;

  ObjectPagamentosCliente({
    this.id,
    this.METODO,
    this.DESCRICAO,
    this.PRECO,
    this.QTDDIV,
    this.selectProduct,
  });

  // Método para converter um objeto Map em um objeto ObjectPagamentosCliente
  factory ObjectPagamentosCliente.fromMap(Map<String, dynamic> map) {
    return ObjectPagamentosCliente(
      id: map['id'],
      METODO: map['METODO'],
      DESCRICAO: map['DESCRICAO'],
      PRECO: map['PRECO'],
      QTDDIV: map['QTDDIV'],
      selectProduct: map['selectProduct'],
    );
  }

  // Método para converter um objeto ObjectPagamentosCliente em um Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'METODO': METODO,
      'DESCRICAO': DESCRICAO,
      'PRECO': PRECO,
      'QTDDIV': QTDDIV,
      'selectProduct': selectProduct,
    };
  }
}
