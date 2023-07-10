import 'package:cloud_firestore/cloud_firestore.dart';

class ObjectObservation {
  String? id;
  String? observacao;
  String? data;
  String? uid;
  bool? checkbox;

  ObjectObservation({
     this.id,
     this.observacao,
     this.data,
     this.uid,
  });
  ObjectObservation.fromMap(dynamic json) {
    id = json['id'];
    observacao = json['OBSERVACAO'];
    data = json['DATA'];
    uid = json['UID'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['OBSERVACAO'] = observacao;
    data['DATA'] = data;
    data['UID'] = uid;

    return data;
  }
}
