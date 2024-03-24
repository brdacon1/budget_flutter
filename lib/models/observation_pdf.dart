import 'package:cloud_firestore/cloud_firestore.dart';

class ObservationPdf {
  String data;
  String observacao;

  ObservationPdf({
    required this.data,
    required this.observacao,
  });

  factory ObservationPdf.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return ObservationPdf(
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
