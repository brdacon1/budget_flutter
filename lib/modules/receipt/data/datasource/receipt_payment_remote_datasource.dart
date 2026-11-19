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

  /// Todos os pagamentos do usuário em 1 consulta `collectionGroup`, limitada
  /// ao caminho do usuário. Cada item traz `budgetId` e `receiptId` (do caminho).
  Future<List<Map<String, dynamic>>> getAllUserPayments(String userUid) async {
    final prefix = 'EMPRESAS/$userUid/USERS/$userUid/';
    final snapshot =
        await _firestore
            .collectionGroup('PAGAMENTOS')
            .orderBy(FieldPath.documentId)
            .startAt([prefix])
            .endAt(['$prefix\uf8ff'])
            .get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      final receipt = d.reference.parent.parent;
      map['id'] = d.id;
      map['receiptId'] = receipt?.id;
      map['budgetId'] = receipt?.parent.parent?.id;
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
