import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as UID;

class PaymentRemoteDataSource {
  final FirebaseFirestore _firestore;
  PaymentRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _paymentsCollection(String budgetId, String receiptId) => _firestore
      .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/$budgetId/RECIBOS/$receiptId/PAGAMENTOS');

  Future<List<Map<String, dynamic>>> getPayments(String budgetId, String receiptId) async {
    final snapshot = await _paymentsCollection(budgetId, receiptId).get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> savePayment(String budgetId, String receiptId, Map<String, dynamic> data) async {
    await _paymentsCollection(budgetId, receiptId).add(data);
  }

  Future<void> updatePayment(String budgetId, String receiptId, String id, Map<String, dynamic> data) async {
    await _paymentsCollection(budgetId, receiptId).doc(id).update(data);
  }

  Future<void> deletePayment(String budgetId, String receiptId, String id) async {
    await _paymentsCollection(budgetId, receiptId).doc(id).delete();
  }
}
