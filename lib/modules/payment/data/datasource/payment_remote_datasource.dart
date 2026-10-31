import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/common/constants/global_uid_budget.dart' as budget;
import 'package:oflite/shared/common/constants/global_uid_user.dart' as UID;

class PaymentRemoteDataSource {
  final FirebaseFirestore _firestore;
  PaymentRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _paymentsCollection => _firestore
      .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${budget.IDORCAMENTO}/RECIBOS/${budget.IDRECIBO}/PAGAMENTOS');

  Future<List<Map<String, dynamic>>> getPayments() async {
    final snapshot = await _paymentsCollection.get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> savePayment(Map<String, dynamic> data) async {
    await _paymentsCollection.add(data);
  }

  Future<void> updatePayment(String id, Map<String, dynamic> data) async {
    await _paymentsCollection.doc(id).update(data);
  }

  Future<void> deletePayment(String id) async {
    await _paymentsCollection.doc(id).delete();
  }
}
