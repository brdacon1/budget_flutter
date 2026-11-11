import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptRemoteDatasource {
  final FirebaseFirestore _firestore;

  ReceiptRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _receiptsCollection(String userUid, String budgetId) =>
      _firestore.collection(
        'EMPRESAS/$userUid/USERS/$userUid/ORCAMENTOS/$budgetId/RECIBOS',
      );

  Future<List<Map<String, dynamic>>> getReceipts(
    String userUid,
    String budgetId,
  ) async {
    final snapshot = await _receiptsCollection(userUid, budgetId).get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> saveReceipt(
    String userUid,
    String budgetId,
    Map<String, dynamic> data,
    String id,
  ) async {
    await _receiptsCollection(userUid, budgetId).doc(id).set(data);
  }

  Future<void> deleteReceipt(String userUid, String budgetId, String id) async {
    await _receiptsCollection(userUid, budgetId).doc(id).delete();
  }
}
