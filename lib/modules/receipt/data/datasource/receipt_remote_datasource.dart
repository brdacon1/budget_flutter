import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as UID;

class ReceiptRemoteDataSource {
  final FirebaseFirestore _firestore;
  ReceiptRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _receiptsCollection(String budgetId) => _firestore
      .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/$budgetId/RECIBOS');

  Future<List<Map<String, dynamic>>> getReceipts(String budgetId) async {
    final snapshot = await _receiptsCollection(budgetId).get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> saveReceipt(String budgetId, Map<String, dynamic> data, String id) async {
    await _receiptsCollection(budgetId).doc(id).set(data);
  }

  Future<void> deleteReceipt(String budgetId, String id) async {
    await _receiptsCollection(budgetId).doc(id).delete();
  }
}
