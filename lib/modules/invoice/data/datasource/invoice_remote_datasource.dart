import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore da coleção `NOTASFISCAIS` de um orçamento.
class InvoiceRemoteDatasource {
  final FirebaseFirestore _firestore;

  InvoiceRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid, String budgetId) =>
      _firestore.collection(
        'EMPRESAS/$uid/USERS/$uid/ORCAMENTOS/$budgetId/NOTASFISCAIS',
      );

  Future<List<Map<String, dynamic>>> getInvoices(
    String uid,
    String budgetId,
  ) async {
    final snap = await _col(uid, budgetId).get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<int> countInvoices(String uid, String budgetId) async {
    final agg = await _col(uid, budgetId).count().get();
    return agg.count ?? 0;
  }

  Future<void> saveInvoice(
    String uid,
    String budgetId,
    String id,
    Map<String, dynamic> data,
  ) => _col(uid, budgetId).doc(id).set(data);

  Future<void> deleteInvoice(String uid, String budgetId, String id) =>
      _col(uid, budgetId).doc(id).delete();
}
