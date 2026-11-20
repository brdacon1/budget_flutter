import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore da coleção `COMPROVANTES` de um orçamento.
class PaymentProofRemoteDatasource {
  final FirebaseFirestore _firestore;

  PaymentProofRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid, String budgetId) =>
      _firestore.collection(
        'EMPRESAS/$uid/USERS/$uid/ORCAMENTOS/$budgetId/COMPROVANTES',
      );

  Future<List<Map<String, dynamic>>> getProofs(
    String uid,
    String budgetId,
  ) async {
    final snap = await _col(uid, budgetId).get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<int> countProofs(String uid, String budgetId) async {
    final agg = await _col(uid, budgetId).count().get();
    return agg.count ?? 0;
  }

  Future<void> saveProof(
    String uid,
    String budgetId,
    String id,
    Map<String, dynamic> data,
  ) => _col(uid, budgetId).doc(id).set(data);

  Future<void> deleteProof(String uid, String budgetId, String id) =>
      _col(uid, budgetId).doc(id).delete();
}
