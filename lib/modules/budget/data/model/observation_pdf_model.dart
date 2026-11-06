import 'package:cloud_firestore/cloud_firestore.dart';

class ObservationPdf {
  String data;
  String observacao;

  ObservationPdf({
    required this.data,
    required this.observacao,
  });

  factory ObservationPdf.fromMap(Map<String, dynamic> map) {
    return ObservationPdf(
      data: map['DATA'] ?? '',
      observacao: map['OBSERVACAO'] ?? '',
    );
  }

  factory ObservationPdf.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return ObservationPdf.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'DATA': data,
      'OBSERVACAO': observacao,
    };
  }
}
