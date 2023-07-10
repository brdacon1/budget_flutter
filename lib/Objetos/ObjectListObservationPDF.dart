import 'package:cloud_firestore/cloud_firestore.dart';

class ObjectListObservationPDF {
  String data;
  String observacao;

  ObjectListObservationPDF({
    required this.data,
    required this.observacao,
  });

  factory ObjectListObservationPDF.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return ObjectListObservationPDF(
      data: data['DATA'] ?? '',
      observacao: data['OBSERVACAO'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'DATA': data,
      'OBSERVACAO': observacao,
    };
  }
}
