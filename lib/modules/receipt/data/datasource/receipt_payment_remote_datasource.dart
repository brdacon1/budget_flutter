import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptPaymentRemoteDatasource {
  final FirebaseFirestore _firestore;

  ReceiptPaymentRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _paymentsCollection(
    String userUid,
    String budgetId,
    String receiptId,
  ) => _firestore.collection(
    'EMPRESAS/$userUid/USERS/$userUid/ORCAMENTOS/$budgetId/RECIBOS/$receiptId/PAGAMENTOS',
  );

  Future<List<Map<String, dynamic>>> getPayments(
    String userUid,
    String budgetId,
    String receiptId,
  ) async {
    final snapshot =
        await _paymentsCollection(userUid, budgetId, receiptId).get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> savePayment(
    String userUid,
    String budgetId,
    String receiptId,
    Map<String, dynamic> data,
  ) async {
    await _paymentsCollection(userUid, budgetId, receiptId).add(data);
  }

  Future<void> updatePayment(
    String userUid,
    String budgetId,
    String receiptId,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _paymentsCollection(
      userUid,
      budgetId,
      receiptId,
    ).doc(id).update(data);
  }

  Future<void> deletePayment(
    String userUid,
    String budgetId,
    String receiptId,
    String id,
  ) async {
    await _paymentsCollection(userUid, budgetId, receiptId).doc(id).delete();
  }
}
