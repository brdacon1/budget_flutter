import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/global_uid_user.dart' as UID;

class ReceiptRemoteDataSource {
  final FirebaseFirestore _firestore;
  ReceiptRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _receiptsCollection => _firestore
      .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${budget.IDORCAMENTO}/RECIBOS');

  Future<List<Map<String, dynamic>>> getReceipts() async {
    final snapshot = await _receiptsCollection.get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> saveReceipt(Map<String, dynamic> data, String id) async {
    await _receiptsCollection.doc(id).set(data);
  }

  Future<void> deleteReceipt(String id) async {
    await _receiptsCollection.doc(id).delete();
  }
}
